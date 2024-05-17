import 'dart:math'; // For the Point class
import 'dart:ui' as ui; // For image handling

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
    // enableTracking: true, // Enable face tracking
    performanceMode:
        FaceDetectorMode.accurate, // Use accurate mode for better results
  ));

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
      detectFaces(imageFile); // Detect faces in the selected image
    } else {
      print('No image selected.');
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

                        return SizedBox(
                          width: _imageInfo.width * scale, // Scale width
                          height: _imageInfo.height * scale, // Scale height
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(_image!),
                              // Display rectangles around detected faces
                              // ..._faces.map((face) => Positioned(
                              //       left: (face.boundingBox.left /
                              //               _imageInfo.width) *
                              //           _imageInfo.width *
                              //           scale,
                              //       top: (face.boundingBox.top /
                              //               _imageInfo.height) *
                              //           _imageInfo.height *
                              //           scale,
                              //       width: (face.boundingBox.width /
                              //               _imageInfo.width) *
                              //           _imageInfo.width *
                              //           scale,
                              //       height: (face.boundingBox.height /
                              //               _imageInfo.height) *
                              //           _imageInfo.height *
                              //           scale,
                              //       child: Container(
                              //         decoration: BoxDecoration(
                              //           border: Border.all(
                              //             color: Colors.red,
                              //             width: 0.5,
                              //           ),
                              //         ),
                              //       ),
                              //     )),
                              // Display contours on detected faces with smaller dots
                              ..._faces.expand((face) =>
                                  face.contours.values.expand((contour) {
                                    if (contour == null) {
                                      return [];
                                    }
                                    return contour.points.map((point) {
                                      final position = point.toDouble();
                                      return Positioned(
                                        left: (position.x / _imageInfo.width) *
                                            _imageInfo.width *
                                            scale,
                                        top: (position.y / _imageInfo.height) *
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
                        );
                      },
                    ),
              const SizedBox(height: 8),
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
