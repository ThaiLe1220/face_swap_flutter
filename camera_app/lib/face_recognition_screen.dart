// ignore_for_file: deprecated_member_use

import 'dart:math'; // For the Point class
import 'dart:ui' as ui; // For image handling

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Flutter UI components
import 'package:image_picker/image_picker.dart'; // For picking images from the gallery
import 'package:google_ml_kit/google_ml_kit.dart'; // Google's ML Kit for face detection
import 'dart:io'; // For File operations

class FaceRecognitionScreen extends StatefulWidget {
  const FaceRecognitionScreen({super.key});

  @override
  FaceRecognitionScreenState createState() => FaceRecognitionScreenState();
}

class FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  File? _image; // The selected image file
  List<Face> _faces = []; // List to store detected faces
  late ui.Image
      _imageInfo; // Image object to get the dimensions of the selected image
  final picker = ImagePicker(); // Image picker instance
  final faceDetector = GoogleMlKit.vision.faceDetector(FaceDetectorOptions(
    enableContours: true, // Enable contour detection
    enableLandmarks: true, // Enable landmark detection
    enableClassification: true, // Enable classification (e.g., smiling)
    enableTracking: true, // Enable face tracking
    performanceMode:
        FaceDetectorMode.accurate, // Use accurate mode for better results
  ));

  String _infoText = ''; // Text to display face information
  String _contourInfoText = ''; // Text to display contour information

  // Function to pick an image from the gallery
  Future pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final imageFile =
          File(pickedFile.path); // Convert picked file to a File object
      final imageInfo = await _loadImage(imageFile); // Load image dimensions
      setState(() {
        _image = imageFile; // Set the selected image
        _imageInfo = imageInfo; // Set the image info with dimensions
      });
      await detectFaces(imageFile); // Detect faces in the selected image
    } else {
      if (kDebugMode) {
        print('No image selected.');
      }
    }
  }

  // Function to load the image and get its dimensions
  Future<ui.Image> _loadImage(File imageFile) async {
    final data = await imageFile.readAsBytes(); // Read image bytes
    return await decodeImageFromList(data); // Decode image to get dimensions
  }

  // Function to detect faces in the selected image
  Future detectFaces(File image) async {
    final inputImage =
        InputImage.fromFile(image); // Create InputImage from file
    final faces = await faceDetector.processImage(inputImage); // Detect faces

    setState(() {
      _faces = faces; // Update the list of detected faces

      // Collect and print face information
      _infoText = '';
      _contourInfoText = '';
      int totalContours = 0;
      for (Face face in _faces) {
        String info = 'Face ID: ${face.trackingId}\n';
        info += 'Smiling Probability: ${face.smilingProbability ?? "N/A"}\n';
        info +=
            'Left Eye Open Probability: ${face.leftEyeOpenProbability ?? "N/A"}\n';
        info +=
            'Right Eye Open Probability: ${face.rightEyeOpenProbability ?? "N/A"}\n';
        if (kDebugMode) {
          print(info);
        } // Print info to console
        _infoText += '$info\n';

        // Collect and print contour information
        for (FaceContourType contourType in face.contours.keys) {
          final contour = face.contours[contourType];
          if (contour != null) {
            _contourInfoText += 'Contour ${contourType.name}:\n';
            for (Point<int> point in contour.points) {
              final position = point.toDouble();
              _contourInfoText += '(${position.x}, ${position.y})\n';
              totalContours++;
            }
          }
        }
      }
      _contourInfoText = 'Total Contours: $totalContours\n\n$_contourInfoText';
      if (kDebugMode) {
        print(_contourInfoText); // Print contour info to console
      }
    });
  }

  @override
  void dispose() {
    faceDetector.close(); // Close the face detector when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Recognition with ML Kit'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _image == null
                  ? const Text('No image selected.')
                  : LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                        double scaleX = constraints.maxWidth / _imageInfo.width;
                        double scaleY =
                            constraints.maxHeight / _imageInfo.height;
                        double scale = min(
                            scaleX, scaleY); // Scale to fit within constraints

                        return Column(
                          children: [
                            SizedBox(
                              width: _imageInfo.width * scale, // Scale width
                              height: _imageInfo.height * scale, // Scale height
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(_image!),
                                  // Display contours on detected faces with smaller dots
                                  ..._faces.expand((face) =>
                                      face.contours.values.expand((contour) {
                                        if (contour == null) {
                                          return [];
                                        }
                                        return contour.points.map((point) {
                                          final position = point.toDouble();
                                          return Positioned(
                                            left: (position.x /
                                                    _imageInfo.width) *
                                                _imageInfo.width *
                                                scale,
                                            top: (position.y /
                                                    _imageInfo.height) *
                                                _imageInfo.height *
                                                scale,
                                            child: const Icon(
                                              Icons.circle,
                                              color: Colors.blue,
                                              size:
                                                  2, // Smaller dot size for contours
                                            ),
                                          );
                                        });
                                      })),
                                ],
                              ),
                            ),
                            // Display face information in a text box
                            Container(
                              padding: const EdgeInsets.all(8.0),
                              color: Colors.black.withOpacity(0.7),
                              child: Text(
                                _infoText,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            // Display contour information in a text box
                            Container(
                              padding: const EdgeInsets.all(8.0),
                              color: Colors.black.withOpacity(0.7),
                              child: Text(
                                _contourInfoText,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed:
                    pickImage, // Button to pick an image from the gallery
                child: const Text('Pick Image'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Extension to convert Point<int> to Point<double>
extension on Point<int> {
  Point<double> toDouble() {
    return Point<double>(x.toDouble(), y.toDouble());
  }
}
