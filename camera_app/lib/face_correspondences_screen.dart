// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class FaceCorrespondencesScreen extends StatefulWidget {
  const FaceCorrespondencesScreen({super.key});

  @override
  FaceCorrespondencesScreenState createState() =>
      FaceCorrespondencesScreenState();
}

class FaceCorrespondencesScreenState extends State<FaceCorrespondencesScreen> {
  File? _image1;
  File? _image2;
  List<Face> _faces1 = [];
  List<Face> _faces2 = [];
  List<Point<double>> _contours1 = [];
  List<Point<double>> _contours2 = [];
  List<Point<double>> _correspondences = [];
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

  String _contourInfoText1 = '';
  String _contourInfoText2 = '';
  String _correspondenceInfoText = '';

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
    String contourInfoText = '';
    int totalContours = 0;

    for (var face in faces) {
      for (var contour in face.contours.values) {
        if (contour != null) {
          for (var point in contour.points) {
            final position = point.toDouble();
            contours.add(position);
            // contourInfoText += '(${position.x}, ${position.y})\n';
            totalContours++;
          }
        }
      }
    }
    contourInfoText = 'Total Contours: $totalContours\n\n$contourInfoText';

    setState(() {
      if (imageNumber == 1) {
        _contours1 = contours;
        _contourInfoText1 = contourInfoText;
        _faces1 = faces;
      } else {
        _contours2 = contours;
        _contourInfoText2 = contourInfoText;
        _faces2 = faces;
      }

      // Compute correspondences if both images are loaded
      if (_contours1.isNotEmpty && _contours2.isNotEmpty) {
        _computeCorrespondences();
      }
    });

    if (kDebugMode) {
      print(contourInfoText);
    }
  }

  void _computeCorrespondences() {
    int count = min(_contours1.length, _contours2.length);
    _correspondences = List.generate(count, (index) {
      return Point(
        (_contours1[index].x + _contours2[index].x) / 2,
        (_contours1[index].y + _contours2[index].y) / 2,
      );
    });

    _correspondenceInfoText = 'Correspondences:\n';
    for (var point in _correspondences) {
      _correspondenceInfoText += '(${point.x}, ${point.y})\n';
    }

    if (kDebugMode) {
      print(_correspondenceInfoText);
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
        title: const Text('Face Correspondences with ML Kit'),
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
                  : _buildImageWithContours(
                      _image1!, _imageInfo1, _contours1, _contourInfoText1),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _pickImage(2),
                child: const Text('Pick Second Image'),
              ),
              _image2 == null
                  ? const Text('No image selected.')
                  : _buildImageWithContours(
                      _image2!, _imageInfo2, _contours2, _contourInfoText2),
              const SizedBox(height: 8),
              if (_image1 != null && _image2 != null) _buildCorrespondences(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageWithContours(File imageFile, ui.Image imageInfo,
      List<Point<double>> contours, String contourInfoText) {
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
                  ...contours.map((point) {
                    return Positioned(
                      left:
                          (point.x / imageInfo.width) * imageInfo.width * scale,
                      top: (point.y / imageInfo.height) *
                          imageInfo.height *
                          scale,
                      child:
                          const Icon(Icons.circle, color: Colors.blue, size: 2),
                    );
                  }),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.black.withOpacity(0.7),
              child: Text(
                contourInfoText,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCorrespondences() {
    return Column(
      children: [
        const Text('Face Correspondences:'),
        const SizedBox(height: 8),
        Text('Contours for Image 1: ${_contours1.length} points'),
        const SizedBox(height: 8),
        Text('Contours for Image 2: ${_contours2.length} points'),
        const SizedBox(height: 8),
        Text('Correspondences: ${_correspondences.length} points'),
        Container(
          padding: const EdgeInsets.all(8.0),
          color: Colors.black.withOpacity(0.7),
          child: Text(
            _correspondenceInfoText,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

// Extension to convert Point<int> to Point<double>
extension on Point<int> {
  Point<double> toDouble() {
    return Point<double>(x.toDouble(), y.toDouble());
  }
}
