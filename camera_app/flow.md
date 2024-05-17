### High-Level Flow

1. **Flutter Application (Dart Code)**
    - The main entry point of the Flutter application resides in Dart code within the `lib` directory.
    - The Flutter app uses the `native_opencv` plugin to access native OpenCV functions.

2. **Flutter Plugin Interface (Dart Code)**
    - The Dart code within the `lib` directory defines the interface for the `native_opencv` plugin.
    - It uses `MethodChannel` to communicate with the native platform code (iOS or Android).
    - When a Dart function is called (e.g., to initialize the detector, destroy the detector, or detect markers), the corresponding method on the `MethodChannel` sends the request to the native platform.

3. **Flutter Plugin Native Interface (Objective-C/Swift for iOS)**
    - The plugin interface for iOS is defined in `NativeOpencvPlugin.h` and `NativeOpencvPlugin.m`.
    - The `NativeOpencvPlugin` class implements the Flutter plugin interface and registers the plugin with the Flutter engine.
    - When the Dart code calls a method via the `MethodChannel`, this method is received by the `NativeOpencvPlugin` class, which then forwards the call to the appropriate Swift class (`native_opencv-Swift.h`).

4. **Swift/Objective-C Code**
    - The Swift implementation (`native_opencv-Swift.h` or its Swift equivalent) bridges the call from the `NativeOpencvPlugin` to the C++ code in `native_opencv.cpp`.
    - It translates method calls from Flutter into native method calls.

5. **C++ Code (OpenCV Integration)**
    - The core logic for interacting with OpenCV is implemented in C++ (`native_opencv.cpp`).
    - Functions like `initDetector`, `destroyDetector`, and `detect` are defined here and are responsible for interfacing with OpenCV to perform image processing tasks.
    - These functions are exposed to the Swift/Objective-C code using `extern "C"` to ensure they can be called from other languages.

6. **Aruco Detector Logic (C++ Code)**
    - The `ArucoDetector` class in `ArucoDetector.cpp` and `ArucoDetector.h` encapsulates the logic for detecting Aruco markers.
    - This class is used by the functions in `native_opencv.cpp` to perform specific tasks such as detecting markers in an image.

### Detailed Interaction Flow

1. **Dart Code Calls Plugin Method**:
    - The Flutter app calls a method provided by the `native_opencv` plugin (e.g., `NativeOpencv.initDetector`).
    - This call uses a `MethodChannel` to communicate with the native side.

2. **MethodChannel Transmits Call**:
    - The `MethodChannel` transmits the method call to the iOS platform.

3. **iOS Plugin Receives Call**:
    - The `NativeOpencvPlugin` class receives the method call.
    - It forwards the call to the appropriate Swift function defined in `native_opencv-Swift.h`.

4. **Swift Code Bridges to C++**:
    - The Swift code translates the method call and arguments into a format suitable for the C++ functions.
    - It calls the relevant C++ function (e.g., `initDetector`).

5. **C++ Code Executes OpenCV Logic**:
    - The C++ function in `native_opencv.cpp` processes the request using OpenCV.
    - For example, `initDetector` initializes the Aruco detector with the provided marker image.

6. **C++ Code Returns Result**:
    - The result of the OpenCV processing is returned from the C++ function to the Swift code.
    - If the function involves image detection, it processes the image and returns the detected markers.

7. **Swift Code Returns Result to Dart**:
    - The Swift code receives the result from the C++ function.
    - It forwards the result back to the Dart side via the `MethodChannel`.

8. **Dart Code Receives Result**:
    - The Dart code receives the result from the `MethodChannel`.
    - The Flutter app can then use the result (e.g., displaying detected markers on the screen).

### How Other Flutter Projects Use the Plugin

1. **Add Dependency**:
    - Other Flutter projects add `native_opencv` as a dependency in their `pubspec.yaml` file.

2. **Import Plugin**:
    - In the Dart code, they import the plugin using `import 'package:native_opencv/native_opencv.dart';`.

3. **Call Plugin Methods**:
    - The Flutter project can call the provided methods in the `NativeOpencv` class to interact with the native OpenCV functionality.
    - For example, they can call `NativeOpencv.initDetector(markerPngBytes, bits)` to initialize the detector, and `NativeOpencv.detect(width, height, rotation, yBuffer, uBuffer, vBuffer)` to detect markers.

### Summary

- The Dart code in the Flutter app interacts with native OpenCV functionality via the `native_opencv` plugin.
- The plugin uses `MethodChannel` to communicate with native code (Objective-C/Swift on iOS).
- The native plugin interface forwards calls from Dart to C++ functions that use OpenCV.
- The C++ code performs image processing tasks and returns results back to the Dart side.
- This setup allows Flutter apps to leverage the power of native libraries like OpenCV for complex image processing tasks.
