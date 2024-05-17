import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:native_opencv/native_opencv.dart';

class FaceMorphScreen extends StatefulWidget {
  const FaceMorphScreen({super.key});

  @override
  FaceMorphScreenState createState() => FaceMorphScreenState();
}

class FaceMorphScreenState extends State<FaceMorphScreen> {
  File? _image1;
  File? _image2;
  String? _outputImagePath;
  List<Point<double>> _contours1 = [];
  List<Point<double>> _contours2 = [];
  List<int> _delaunayTriangles = [];
  late ui.Image _imageInfo1;
  late ui.Image _imageInfo2;
  final picker = ImagePicker();
  final faceDetector = GoogleMlKit.vision.faceDetector(FaceDetectorOptions(
    enableContours: true,
    enableLandmarks: true,
    enableClassification: true,
    enableTracking: true,
    performanceMode: FaceDetectorMode.accurate,
  ));
  final NativeOpencv _nativeOpencv = NativeOpencv();

  Future<void> _pickImage(int imageNumber) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      final imageInfo = await _loadImage(imageFile);
      setState(() {
        if (imageNumber == 1) {
          _image1 = imageFile;
          _imageInfo1 = imageInfo;
        } else {
          _image2 = imageFile;
          _imageInfo2 = imageInfo;
        }
      });
      await _detectFaces(imageFile, imageNumber);
    } else {
      if (kDebugMode) {
        print('No image selected.');
      }
    }
  }

  Future<ui.Image> _loadImage(File imageFile) async {
    final data = await imageFile.readAsBytes();
    return await decodeImageFromList(data);
  }

  Future<void> _detectFaces(File image, int imageNumber) async {
    final inputImage = InputImage.fromFile(image);
    final faces = await faceDetector.processImage(inputImage);
    List<Point<double>> contours = [];
    for (var face in faces) {
      for (var contour in face.contours.values) {
        if (contour != null) {
          for (var point in contour.points) {
            contours.add(Point(point.x.toDouble(), point.y.toDouble()));
          }
        }
      }
    }
    setState(() {
      if (imageNumber == 1) {
        _contours1 = contours;
      } else {
        _contours2 = contours;
      }

      // Compute correspondences and Delaunay triangulation if both images are loaded
      if (_contours1.isNotEmpty && _contours2.isNotEmpty) {
        _computeCorrespondences();
        _computeDelaunay();
      }
    });

    if (kDebugMode) {
      print('Total Contours (Image $imageNumber): ${contours.length}');
      for (var point in contours) {
        print('Contour Point: (${point.x}, ${point.y})');
      }
    }
  }

  void _computeCorrespondences() {
    int count = min(_contours1.length, _contours2.length);
    List<Point<double>> correspondences = List.generate(count, (index) {
      return Point(
        (_contours1[index].x + _contours2[index].x) / 2,
        (_contours1[index].y + _contours2[index].y) / 2,
      );
    });
    if (kDebugMode) {
      print('Total Correspondences: ${correspondences.length}');
      for (var point in correspondences) {
        print('Correspondence Point: (${point.x}, ${point.y})');
      }
    }
  }

  void _computeDelaunay() {
    if (_contours1.isEmpty || _contours2.isEmpty) return;

    final points = _contours1.expand((point) => [point.x, point.y]).toList();
    try {
      final delaunayTriangles = _nativeOpencv.makeDelaunay(
        _imageInfo1.width.toInt(),
        _imageInfo1.height.toInt(),
        points,
      );
      setState(() {
        _delaunayTriangles = delaunayTriangles;
      });

      if (kDebugMode) {
        print(
            'Delaunay Triangles: ${_delaunayTriangles.length ~/ 3} triangles');
        for (int i = 0; i < _delaunayTriangles.length; i += 3) {
          print(
              'Triangle: (${_delaunayTriangles[i]}, ${_delaunayTriangles[i + 1]}, ${_delaunayTriangles[i + 2]})');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error computing Delaunay triangulation: $e');
      }
    }
  }

  Future<void> _morphImages(double alpha) async {
    if (_image1 == null ||
        _image2 == null ||
        _contours1.isEmpty ||
        _contours2.isEmpty ||
        _delaunayTriangles.isEmpty) {
      return;
    }

    final img1Path = _image1!.path;
    final img2Path = _image2!.path;
    final outputPath = '${Directory.systemTemp.path}/morphed_image.png';

    final points1 = _contours1.expand((point) => [point.x, point.y]).toList();
    final points2 = _contours2.expand((point) => [point.x, point.y]).toList();

    try {
      _nativeOpencv.morphImages(
        img1Path,
        img2Path,
        points1,
        points2,
        _delaunayTriangles,
        alpha,
        outputPath,
      );

      setState(() {
        _outputImagePath = outputPath;
      });

      if (kDebugMode) {
        print('Morphed image saved to $outputPath');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error morphing images: $e');
      }
    }
  }

  @override
  void dispose() {
    faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Morphing with ML Kit and OpenCV'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: () => _pickImage(1),
                child: const Text('Pick First Image'),
              ),
              _image1 == null
                  ? const Text('No image selected.')
                  : _buildImage(_image1!, _imageInfo1),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _pickImage(2),
                child: const Text('Pick Second Image'),
              ),
              _image2 == null
                  ? const Text('No image selected.')
                  : _buildImage(_image2!, _imageInfo2),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _morphImages(0.5),
                child: const Text('Morph Images'),
              ),
              _outputImagePath == null
                  ? const Text('No morphed image.')
                  : Image.file(File(_outputImagePath!)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(File imageFile, ui.Image imageInfo) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double scaleX = constraints.maxWidth / imageInfo.width;
        double scaleY = constraints.maxHeight / imageInfo.height;
        double scale = min(scaleX, scaleY);
        return SizedBox(
          width: imageInfo.width * scale,
          height: imageInfo.height * scale,
          child: Image.file(imageFile),
        );
      },
    );
  }
}
