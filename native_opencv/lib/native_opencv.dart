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

// Bind the Dart functions to the C functions in the shared library
final _version = nativeLib.lookupFunction<_c_version, _dart_version>('version');
final _convertToGrayScale =
    nativeLib.lookupFunction<_c_convertToGrayScale, _dart_convertToGrayScale>(
        'convertToGrayScale');
final _makeDelaunay = nativeLib
    .lookupFunction<_c_makeDelaunay, _dart_makeDelaunay>('makeDelaunay');

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
}
