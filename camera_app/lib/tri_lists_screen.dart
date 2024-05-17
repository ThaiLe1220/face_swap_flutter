// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:native_opencv/native_opencv.dart';

class TriListsScreen extends StatefulWidget {
  const TriListsScreen({super.key});

  @override
  TriListsScreenState createState() => TriListsScreenState();
}

class TriListsScreenState extends State<TriListsScreen> {
  File? _image;
  List<Face> _faces = [];
  List<Point<double>> _contours = [];
  List<int> _delaunayTriangles = [];
  late ui.Image _imageInfo;
  final picker = ImagePicker();
  final faceDetector = GoogleMlKit.vision.faceDetector(FaceDetectorOptions(
    enableContours: true,
    enableLandmarks: true,
    enableClassification: true,
    enableTracking: true,
    performanceMode: FaceDetectorMode.accurate,
  ));
  final NativeOpencv _nativeOpencv = NativeOpencv();

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      final imageInfo = await _loadImage(imageFile);
      setState(() {
        _image = imageFile;
        _imageInfo = imageInfo;
      });
      await _detectFaces(imageFile);
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

  Future<void> _detectFaces(File image) async {
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
      _faces = faces;
      _contours = contours;
      _computeDelaunay();
    });

    if (kDebugMode) {
      print('Total Contours: ${contours.length}');
      for (var point in contours) {
        print('Contour Point: (${point.x}, ${point.y})');
      }
    }
  }

  void _computeDelaunay() {
    if (_contours.isEmpty) return;

    final points = _contours.expand((point) => [point.x, point.y]).toList();
    try {
      final delaunayTriangles = _nativeOpencv.makeDelaunay(
        _imageInfo.width.toInt(),
        _imageInfo.height.toInt(),
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

  @override
  void dispose() {
    faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delaunay Triangulation with ML Kit'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Pick Image'),
              ),
              _image == null
                  ? const Text('No image selected.')
                  : _buildImageWithContoursAndTriangles(
                      _image!, _imageInfo, _contours, _delaunayTriangles),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageWithContoursAndTriangles(File imageFile, ui.Image imageInfo,
      List<Point<double>> contours, List<int> delaunayTriangles) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double scaleX = constraints.maxWidth / imageInfo.width;
        double scaleY = constraints.maxHeight / imageInfo.height;
        double scale = min(scaleX, scaleY);
        return Column(
          children: [
            SizedBox(
              width: imageInfo.width * scale,
              height: imageInfo.height * scale,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(imageFile),
                  ...delaunayTriangles.map((index) {
                    final point = contours[index];
                    return Positioned(
                      left:
                          (point.x / imageInfo.width) * imageInfo.width * scale,
                      top: (point.y / imageInfo.height) *
                          imageInfo.height *
                          scale,
                      child:
                          const Icon(Icons.circle, color: Colors.red, size: 2),
                    );
                  }),
                ],
              ),
            ),
            // Display Delaunay triangles points in a text box
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.black.withOpacity(0.7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Delaunay Triangles:',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  for (int i = 0; i < _delaunayTriangles.length; i += 3)
                    Text(
                      'Triangle ${i ~/ 3 + 1}: (${_delaunayTriangles[i]}, ${_delaunayTriangles[i + 1]}, ${_delaunayTriangles[i + 2]})',
                      style: const TextStyle(color: Colors.white),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
