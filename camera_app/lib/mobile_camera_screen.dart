import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:native_opencv/native_opencv.dart';

class MobileCameraScreen extends StatefulWidget {
  const MobileCameraScreen({super.key});
  @override
  MobileCameraScreenState createState() => MobileCameraScreenState();
}

class MobileCameraScreenState extends State<MobileCameraScreen> {
  final List<File> _imageFiles = [];
  final List<File> _originalImageFiles = [];
  int _currentIndex = 0;
  final ImagePicker _picker = ImagePicker();
  bool _isGrayscale = false;
  bool _isProcessing = false; // Flag to prevent multiple operations

  final NativeOpencv _opencv = NativeOpencv(); // Instance of NativeOpencv

  Future<void> _pickImage() async {
    if (_isProcessing) return; // Prevent multiple operations
    _isProcessing = true;

    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        setState(() {
          _imageFiles.add(imageFile);
          _originalImageFiles
              .add(File(pickedFile.path)); // Keep a copy of the original image
          _currentIndex = _imageFiles.length - 1;
          _isGrayscale =
              false; // Reset grayscale flag when a new image is picked
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }

    _isProcessing = false;
  }

  Future<void> _convertToGrayscale() async {
    if (_imageFiles.isEmpty || _isProcessing) {
      return; // Prevent multiple operations
    }
    _isProcessing = true;

    try {
      if (_isGrayscale) {
        // Revert to original image
        setState(() {
          _imageFiles[_currentIndex] = _originalImageFiles[_currentIndex];
          _isGrayscale = false;
        });
      } else {
        // Convert to grayscale using native plugin
        final directory = await getTemporaryDirectory();
        final outputPath =
            '${directory.path}/${DateTime.now().millisecondsSinceEpoch}_gray.png';
        _opencv.convertToGrayScale(
          _originalImageFiles[_currentIndex].path,
          outputPath,
        );

        final grayImageFile = File(outputPath);
        if (await grayImageFile.exists()) {
          setState(() {
            _imageFiles[_currentIndex] = grayImageFile;
            _isGrayscale = true;
          });
        }
      }
    } catch (e) {
      print('Error converting image: $e');
      setState(() {
        _isGrayscale = false; // Revert the grayscale flag on error
      });
    }

    _isProcessing = false;
  }

  void _showNextImage() {
    if (_isProcessing) return; // Prevent multiple operations

    setState(() {
      if (_currentIndex < _imageFiles.length - 1) {
        _currentIndex++;
        _isGrayscale = false; // Reset grayscale flag when switching images
      }
    });
  }

  void _showPreviousImage() {
    if (_isProcessing) return; // Prevent multiple operations

    setState(() {
      if (_currentIndex > 0) {
        _currentIndex--;
        _isGrayscale = false; // Reset grayscale flag when switching images
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Image'),
        toolbarHeight: 35.0,
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
                    padding: const EdgeInsets.all(0),
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
                    child: ElevatedButton(
                      onPressed: _convertToGrayscale,
                      child: Text(_isGrayscale
                          ? 'Revert to Normal'
                          : 'Convert to Grayscale'),
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
