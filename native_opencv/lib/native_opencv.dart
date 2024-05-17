// ignore_for_file: camel_case_types, non_constant_identifier_names

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';

// Load the native library dynamically
final DynamicLibrary nativeLib = Platform.isAndroid
    ? DynamicLibrary.open("libnative_opencv.so")
    : DynamicLibrary.process();

// Define the signatures of the C functions
// Define the signatures of the C functions
typedef _c_version = Pointer<Utf8> Function();
typedef _c_convertToGrayScale = Pointer<Utf8> Function(
    Pointer<Utf8> inputImagePath, Pointer<Utf8> outputImagePath);
typedef _c_makeDelaunay = Pointer<Utf8> Function(
    Int32 f_w,
    Int32 f_h,
    Pointer<Float> points,
    Int32 points_size,
    Pointer<Int32> result,
    Pointer<Int32> result_size);
typedef _c_morphImages = Pointer<Utf8> Function(
    Pointer<Utf8> img1Path,
    Pointer<Utf8> img2Path,
    Pointer<Float> points1,
    Pointer<Float> points2,
    Pointer<Int32> triangles,
    Int32 numTriangles,
    Float alpha,
    Pointer<Utf8> outputPath);

// Define the Dart functions that correspond to the C functions
typedef _dart_version = Pointer<Utf8> Function();
typedef _dart_convertToGrayScale = Pointer<Utf8> Function(
    Pointer<Utf8> inputImagePath, Pointer<Utf8> outputImagePath);
typedef _dart_makeDelaunay = Pointer<Utf8> Function(
    int f_w,
    int f_h,
    Pointer<Float> points,
    int points_size,
    Pointer<Int32> result,
    Pointer<Int32> result_size);
typedef _dart_morphImages = Pointer<Utf8> Function(
    Pointer<Utf8> img1Path,
    Pointer<Utf8> img2Path,
    Pointer<Float> points1,
    Pointer<Float> points2,
    Pointer<Int32> triangles,
    int numTriangles,
    double alpha,
    Pointer<Utf8> outputPath);

// Bind the Dart functions to the C functions in the shared library
final _version = nativeLib.lookupFunction<_c_version, _dart_version>('version');
final _convertToGrayScale =
    nativeLib.lookupFunction<_c_convertToGrayScale, _dart_convertToGrayScale>(
        'convertToGrayScale');
final _makeDelaunay = nativeLib
    .lookupFunction<_c_makeDelaunay, _dart_makeDelaunay>('makeDelaunay');
final _morphImages =
    nativeLib.lookupFunction<_c_morphImages, _dart_morphImages>('morphImages');

class NativeOpencv {
  // Method channel for platform version
  static const MethodChannel _channel = MethodChannel('native_opencv');

  // Asynchronously get the platform version
  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  // Get the OpenCV version
  String cvVersion() {
    return _version().toDartString();
  }

  // Convert an image to grayscale
  void convertToGrayScale(String inputImagePath, String outputImagePath) {
    final inputPath = inputImagePath.toNativeUtf8();
    final outputPath = outputImagePath.toNativeUtf8();

    _convertToGrayScale(inputPath, outputPath);

    malloc.free(inputPath);
    malloc.free(outputPath);
  }

  List<int> makeDelaunay(int f_w, int f_h, List<double> points) {
    final pointsPointer = malloc<Float>(points.length);
    final resultPointer = malloc<Int32>(points.length * 3);
    final resultSizePointer = malloc<Int32>(1);

    for (int i = 0; i < points.length; i++) {
      pointsPointer[i] = points[i];
    }

    final result = _makeDelaunay(f_w, f_h, pointsPointer, points.length,
        resultPointer, resultSizePointer);

    malloc.free(pointsPointer);

    if (result != nullptr) {
      final errorMessage = result.toDartString();
      malloc.free(resultPointer);
      malloc.free(resultSizePointer);
      throw Exception(errorMessage);
    }

    final resultSize = resultSizePointer.value;
    final resultList = List<int>.generate(resultSize, (i) => resultPointer[i]);

    malloc.free(resultPointer);
    malloc.free(resultSizePointer);

    return resultList;
  }

  void morphImages(
      String img1Path,
      String img2Path,
      List<double> points1,
      List<double> points2,
      List<int> triangles,
      double alpha,
      String outputPath) {
    final img1PathPointer = img1Path.toNativeUtf8();
    final img2PathPointer = img2Path.toNativeUtf8();
    final points1Pointer = malloc<Float>(points1.length);
    final points2Pointer = malloc<Float>(points2.length);
    final trianglesPointer = malloc<Int32>(triangles.length);
    final outputPathPointer = outputPath.toNativeUtf8();

    for (int i = 0; i < points1.length; i++) {
      points1Pointer[i] = points1[i];
    }
    for (int i = 0; i < points2.length; i++) {
      points2Pointer[i] = points2[i];
    }
    for (int i = 0; i < triangles.length; i++) {
      trianglesPointer[i] = triangles[i];
    }

    final result = _morphImages(
        img1PathPointer,
        img2PathPointer,
        points1Pointer,
        points2Pointer,
        trianglesPointer,
        triangles.length,
        alpha,
        outputPathPointer);

    malloc.free(img1PathPointer);
    malloc.free(img2PathPointer);
    malloc.free(points1Pointer);
    malloc.free(points2Pointer);
    malloc.free(trianglesPointer);
    malloc.free(outputPathPointer);

    if (result != nullptr) {
      final errorMessage = result.toDartString();
      throw Exception(errorMessage);
    }
  }
}
