// ignore_for_file: deprecated_member_use

import 'dart:io'; // For File operations
import 'dart:math'; // For mathematical functions and calculations
import 'dart:ui' as ui; // For handling images
import 'package:camera_app/utils/face_morph_utils.dart'; // Custom utility functions for face morphing
import 'package:flutter/material.dart'; // For UI components

// Main widget for the Face Morphing screen
class FaceMorphScreen extends StatefulWidget {
  const FaceMorphScreen({super.key});

  @override
  FaceMorphScreenState createState() => FaceMorphScreenState();
}

// State class for FaceMorphScreen
class FaceMorphScreenState extends State<FaceMorphScreen> {
  // Variables to hold the selected images and their corresponding info
  File? _image1;
  File? _image2;
  String? _outputImagePath;
  List<Point<double>> _contours1 = [];
  List<Point<double>> _contours2 = [];
  List<int> _delaunayTriangles = [];
  late ui.Image _imageInfo1;
  late ui.Image _imageInfo2;

  // Add variables to store the elapsed time
  Duration? _pickImage1Time;
  Duration? _pickImage2Time;
  Duration? _detectFaces1Time;
  Duration? _detectFaces2Time;
  Duration? _morphImageTime;

  // Dispose resources when the widget is removed from the widget tree
  @override
  void dispose() {
    disposeResources();
    super.dispose();
  }

  // Build the UI for the screen
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
              // Button to pick the first image
              ElevatedButton(
                onPressed: () => pickImage(
                  1,
                  (imageFile, imageInfo) =>
                      _onImagePicked(imageFile, imageInfo, 1),
                  (elapsed) {
                    setState(() {
                      _pickImage1Time = elapsed;
                    });
                  },
                  detectFacesWithTiming,
                  (elapsed) {
                    setState(() {
                      _detectFaces1Time = elapsed;
                    });
                  },
                ),
                child: const Text('Pick First Image'),
              ),
              // Display the first image if selected
              _image1 == null
                  ? const Text('No image selected.')
                  : _buildImage(_image1!, _imageInfo1),
              const SizedBox(height: 8),
              // Button to pick the second image
              ElevatedButton(
                onPressed: () => pickImage(
                  2,
                  (imageFile, imageInfo) =>
                      _onImagePicked(imageFile, imageInfo, 2),
                  (elapsed) {
                    setState(() {
                      _pickImage2Time = elapsed;
                    });
                  },
                  detectFacesWithTiming,
                  (elapsed) {
                    setState(() {
                      _detectFaces2Time = elapsed;
                    });
                  },
                ),
                child: const Text('Pick Second Image'),
              ),
              // Display the second image if selected
              _image2 == null
                  ? const Text('No image selected.')
                  : _buildImage(_image2!, _imageInfo2),
              const SizedBox(height: 8),
              // Button to morph the images
              ElevatedButton(
                onPressed: () => morphImages(
                  _image1,
                  _image2,
                  _contours1,
                  _contours2,
                  _delaunayTriangles,
                  0.5,
                  _onImageMorphed,
                  (elapsed) {
                    setState(() {
                      _morphImageTime = elapsed;
                    });
                  },
                ),
                child: const Text('Morph Images'),
              ),
              // Display the morphed image if available
              _outputImagePath == null
                  ? const Text('No morphed image.')
                  : Image.file(File(_outputImagePath!)),
              // Display the elapsed times
              if (_pickImage1Time != null)
                Text(
                    'Time taken to pick image 1: ${_pickImage1Time!.inMilliseconds} ms'),
              if (_detectFaces1Time != null)
                Text(
                    'Time taken to detect faces in image 1: ${_detectFaces1Time!.inMilliseconds} ms'),
              if (_pickImage2Time != null)
                Text(
                    'Time taken to pick image 2: ${_pickImage2Time!.inMilliseconds} ms'),
              if (_detectFaces2Time != null)
                Text(
                    'Time taken to detect faces in image 2: ${_detectFaces2Time!.inMilliseconds} ms'),
              if (_morphImageTime != null)
                Text(
                    'Time taken to morph images: ${_morphImageTime!.inMilliseconds} ms'),
            ],
          ),
        ),
      ),
    );
  }

  // Callback function when an image is picked
  void _onImagePicked(File imageFile, ui.Image imageInfo, int imageNumber) {
    setState(() {
      if (imageNumber == 1) {
        _image1 = imageFile;
        _imageInfo1 = imageInfo;
        _contours1.clear(); // Clear previous contours for image1
      } else if (imageNumber == 2) {
        _image2 = imageFile;
        _imageInfo2 = imageInfo;
        _contours2.clear(); // Clear previous contours for image2
      }
      _delaunayTriangles.clear(); // Clear previous Delaunay triangles
      _outputImagePath = null; // Clear the morphed image path
    });
    // Detect faces after image is picked
    detectFacesWithTiming(imageFile, imageNumber, (contours) {
      setState(() {
        if (imageNumber == 1) {
          _contours1 = contours;
        } else {
          _contours2 = contours;
        }

        if (_contours1.isNotEmpty && _contours2.isNotEmpty) {
          computeCorrespondences(_contours1, _contours2, (correspondences) {
            computeDelaunay(_contours1, _imageInfo1, (delaunayTriangles) {
              setState(() {
                _delaunayTriangles = delaunayTriangles;
              });
            });
          });
        }
      });
    }, (elapsed) {
      setState(() {
        if (imageNumber == 1) {
          _detectFaces1Time = elapsed;
        } else {
          _detectFaces2Time = elapsed;
        }
      });
    });
  }

  // Callback function when the images are morphed
  void _onImageMorphed(String outputPath) {
    setState(() {
      _outputImagePath = outputPath;
    });
  }

  // Widget to display the selected image
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
