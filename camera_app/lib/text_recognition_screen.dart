// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Flutter UI components
import 'package:image_picker/image_picker.dart'; // For picking images from the gallery
import 'package:google_ml_kit/google_ml_kit.dart'; // Google's ML Kit for text recognition
import 'dart:io'; // For File operations

// Stateful widget for the text recognition screen
class TextRecognitionScreen extends StatefulWidget {
  const TextRecognitionScreen({super.key});

  @override
  TextRecognitionScreenState createState() => TextRecognitionScreenState();
}

class TextRecognitionScreenState extends State<TextRecognitionScreen> {
  File? _image; // Variable to store the selected image file
  String _recognizedText =
      'No text recognized yet.'; // Variable to store the recognized text

  final picker = ImagePicker(); // Image picker instance
  final textRecognizer =
      GoogleMlKit.vision.textRecognizer(); // Instance of the text recognizer

  // Function to pick an image from the gallery
  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path); // Set the selected image
      });
      recognizeText(_image!); // Recognize text in the selected image
    } else {
      if (kDebugMode) {
        print('No image selected.');
      }
    }
  }

  // Function to recognize text in the selected image
  Future<void> recognizeText(File image) async {
    final inputImage =
        InputImage.fromFile(image); // Create InputImage from file
    final recognizedText =
        await textRecognizer.processImage(inputImage); // Recognize text

    setState(() {
      _recognizedText = recognizedText.text; // Update the recognized text
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Text Recognition with ML Kit'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _image == null
                  ? const Text('No image selected.')
                  : Image.file(_image!), // Display the selected image
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed:
                    pickImage, // Button to pick an image from the gallery
                child: const Text('Pick Image'),
              ),
              const SizedBox(height: 16),
              Text(
                _recognizedText, // Display the recognized text
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
