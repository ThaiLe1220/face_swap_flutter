import 'package:flutter/material.dart';
import 'mobile_camera_screen.dart';
import 'text_recognition_screen.dart';
import 'face_recognition_screen.dart'; // Import the face recognition screen
import 'face_correspondences_screen.dart'; // Import the new screen

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
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Media Upload Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MobileCameraScreen()),
                );
              },
              child: const Text('Go to Camera Screen'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const TextRecognitionScreen()),
                );
              },
              child: const Text('Go to Text Recognition Screen'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FaceRecognitionScreen()),
                );
              },
              child: const Text('Go to Face Recognition Screen'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FaceCorrespondencesScreen()),
                );
              },
              child: const Text('Go to Face Correspondences Screen'),
            ),
          ],
        ),
      ),
    );
  }
}
