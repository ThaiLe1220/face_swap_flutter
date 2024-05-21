// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:native_opencv/native_opencv.dart';

// Create an instance of ImagePicker for picking images from the gallery
final picker = ImagePicker();

// Configure the face detector with options to enable contours, landmarks, classification, and tracking
final faceDetector = GoogleMlKit.vision.faceDetector(FaceDetectorOptions(
  enableContours: true,
  // enableLandmarks: true,
  // enableClassification: true,
  // enableTracking: true,
  performanceMode: FaceDetectorMode.fast,
));

// Create an instance of NativeOpencv for performing OpenCV operations
final NativeOpencv nativeOpencv = NativeOpencv();

// Function to pick an image from the gallery with time measurement
Future<void> pickImage(
  int imageNumber,
  Function(File, ui.Image) onImagePicked,
  Function(Duration) onTimeMeasured,
  Function(File, int, Function(List<Point<double>>), Function(Duration))
      onDetectFaces,
  Function(Duration) onDetectTimeMeasured,
) async {
  final stopwatch = Stopwatch()..start();

  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
  if (pickedFile != null) {
    final imageFile = File(pickedFile.path);
    final imageInfo = await loadImage(imageFile);

    stopwatch.stop();
    onTimeMeasured(stopwatch.elapsed);

    // Call the provided callback function with the picked image file and its information
    onImagePicked(imageFile, imageInfo);

    // Measure time for face detection
    await onDetectFaces(
        imageFile, imageNumber, (contours) {}, onDetectTimeMeasured);
  } else {
    stopwatch.stop();
    onTimeMeasured(stopwatch.elapsed);

    if (kDebugMode) {
      print('No image selected.');
    }
  }
}

// Function to load an image and return its information as a ui.Image object
Future<ui.Image> loadImage(File imageFile) async {
  final data = await imageFile.readAsBytes();
  return await decodeImageFromList(data);
}

// Function to decode a Uint8List of image data into a ui.Image object
Future<ui.Image> decodeImageFromList(Uint8List data) async {
  final codec = await ui.instantiateImageCodec(data);
  final frame = await codec.getNextFrame();
  return frame.image;
}

// Function to detect faces in an image and extract their contours with timing
Future<void> detectFacesWithTiming(
    File image,
    int imageNumber,
    Function(List<Point<double>>) onContoursDetected,
    Function(Duration) onTimeMeasured) async {
  final stopwatch = Stopwatch()..start();

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

  stopwatch.stop();
  onTimeMeasured(stopwatch.elapsed);

  // Call the provided callback function with the detected contours
  onContoursDetected(contours);

  if (kDebugMode) {
    print('Total Contours (Image $imageNumber): ${contours.length}');
    for (var point in contours) {
      print('Contour Point: (${point.x}, ${point.y})');
    }
  }
}

// Function to compute correspondences between contours from two images
void computeCorrespondences(
    List<Point<double>> contours1,
    List<Point<double>> contours2,
    Function(List<Point<double>>) onCorrespondencesComputed) {
  int count = min(contours1.length, contours2.length);
  List<Point<double>> correspondences = List.generate(count, (index) {
    return Point(
      (contours1[index].x + contours2[index].x) / 2,
      (contours1[index].y + contours2[index].y) / 2,
    );
  });
  // Call the provided callback function with the computed correspondences
  onCorrespondencesComputed(correspondences);

  if (kDebugMode) {
    print('Total Correspondences: ${correspondences.length}');
    for (var point in correspondences) {
      print('Correspondence Point: (${point.x}, ${point.y})');
    }
  }
}

// Function to compute Delaunay triangulation for the contours of the first image
void computeDelaunay(List<Point<double>> contours1, ui.Image imageInfo1,
    Function(List<int>) onDelaunayComputed) {
  if (contours1.isEmpty) return;

  final points = contours1.expand((point) => [point.x, point.y]).toList();
  try {
    final delaunayTriangles = nativeOpencv.makeDelaunay(
      imageInfo1.width.toInt(),
      imageInfo1.height.toInt(),
      points,
    );
    // Call the provided callback function with the computed Delaunay triangles
    onDelaunayComputed(delaunayTriangles);

    if (kDebugMode) {
      print('Delaunay Triangles: ${delaunayTriangles.length ~/ 3} triangles');
      for (int i = 0; i < delaunayTriangles.length; i += 3) {
        print(
            'Triangle: (${delaunayTriangles[i]}, ${delaunayTriangles[i + 1]}, ${delaunayTriangles[i + 2]})');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error computing Delaunay triangulation: $e');
    }
  }
}

// Function to compute Delaunay triangulation for the contours of the first image
void computeDelaunayWithTime(List<Point<double>> contours1, ui.Image imageInfo1,
    Function(List<int>) onDelaunayComputed, Function(Duration) onTimeMeasured) {
  if (contours1.isEmpty) return;
  final stopwatch = Stopwatch()..start();
  final points = contours1.expand((point) => [point.x, point.y]).toList();
  try {
    final delaunayTriangles = nativeOpencv.makeDelaunay(
      imageInfo1.width.toInt(),
      imageInfo1.height.toInt(),
      points,
    );
    // Call the provided callback function with the computed Delaunay triangles
    onDelaunayComputed(delaunayTriangles);
    stopwatch.stop();
    onTimeMeasured(stopwatch.elapsed);
    
    if (kDebugMode) {
      print('Delaunay Triangles: ${delaunayTriangles.length ~/ 3} triangles');
      for (int i = 0; i < delaunayTriangles.length; i += 3) {
        print(
            'Triangle: (${delaunayTriangles[i]}, ${delaunayTriangles[i + 1]}, ${delaunayTriangles[i + 2]})');
      }
      print('Total time for Delaunay: ${stopwatch.elapsed.inMilliseconds} ms');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error computing Delaunay triangulation: $e');
    }
  }
}

// Function to morph two images using the computed Delaunay triangulation and contours with time measurement
Future<void> morphImages(
  File? image1,
  File? image2,
  List<Point<double>> contours1,
  List<Point<double>> contours2,
  List<int> delaunayTriangles,
  double alpha,
  Function(String) onImageMorphed,
  Function(Duration) onTimeMeasured,
) async {
  final stopwatch = Stopwatch()..start();

  if (image1 == null ||
      image2 == null ||
      contours1.isEmpty ||
      contours2.isEmpty ||
      delaunayTriangles.isEmpty) {
    stopwatch.stop();
    onTimeMeasured(stopwatch.elapsed);
    return;
  }

  final img1Path = image1.path;
  final img2Path = image2.path;
  final outputPath = '${Directory.systemTemp.path}/morphed_image.png';

  final points1 = contours1.expand((point) => [point.x, point.y]).toList();
  final points2 = contours2.expand((point) => [point.x, point.y]).toList();

  try {
    nativeOpencv.morphImages(
      img1Path,
      img2Path,
      points1,
      points2,
      delaunayTriangles,
      alpha,
      outputPath,
    );

    stopwatch.stop();
    onTimeMeasured(stopwatch.elapsed);

    // Call the provided callback function with the path of the morphed image
    onImageMorphed(outputPath);

    if (kDebugMode) {
      print('Morphed image saved to $outputPath');
    }
  } catch (e) {
    stopwatch.stop();
    onTimeMeasured(stopwatch.elapsed);

    if (kDebugMode) {
      print('Error morphing images: $e');
    }
  }
}

// Function to dispose of resources when they are no longer needed
void disposeResources() {
  faceDetector.close();
}
