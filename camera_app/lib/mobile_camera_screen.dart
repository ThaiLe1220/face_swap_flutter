import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MobileCameraScreen extends StatefulWidget {
  const MobileCameraScreen({super.key});
  @override
  MobileCameraScreenState createState() => MobileCameraScreenState();
}

class MobileCameraScreenState extends State<MobileCameraScreen> {
  final List<File> _imageFiles = [];
  int _currentIndex = 0;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFiles.add(File(pickedFile.path));
        _currentIndex = _imageFiles.length - 1;
      });
    }
  }

  void _showNextImage() {
    setState(() {
      if (_currentIndex < _imageFiles.length - 1) {
        _currentIndex++;
      }
    });
  }

  void _showPreviousImage() {
    setState(() {
      if (_currentIndex > 0) {
        _currentIndex--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Image'),
        toolbarHeight: 40.0, // Reduce the height of the app bar
      ),
      body: Center(
        child: _imageFiles.isEmpty
            ? const Text('No image selected.')
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: Image.file(_imageFiles[_currentIndex],
                          fit: BoxFit.contain),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed:
                              _currentIndex > 0 ? _showPreviousImage : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: _currentIndex < _imageFiles.length - 1
                              ? _showNextImage
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        tooltip: 'Pick Image',
        child: const Icon(Icons.photo),
      ),
    );
  }
}
