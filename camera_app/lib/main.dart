import 'package:flutter/material.dart';
import 'mobile_camera_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Media Upload Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MobileCameraScreen(),
    );
  }
}
