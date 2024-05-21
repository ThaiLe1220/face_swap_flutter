import 'package:flutter/material.dart';
import 'screens/mobile_camera_screen.dart';
import 'screens/text_recognition_screen.dart';
import 'screens/face_recognition_screen.dart';
import 'screens/face_correspondences_screen.dart';
import 'screens/face_morph_screen.dart';
import 'screens/tri_lists_screen.dart';
import 'screens/video_upload_screen.dart';
import 'screens/video_player_screen.dart'; // Import the new screen
import 'screens/face_morph_screen_dev.dart';

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
        child: SingleChildScrollView(
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
                child: const Text('Camera Screen'),
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
                child: const Text('Text Recognition Screen'),
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
                child: const Text('Face Recognition Screen'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const FaceCorrespondencesScreen()),
                  );
                },
                child: const Text('Face Correspondences Screen'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const TriListsScreen()),
                  );
                },
                child: const Text('Tri Lists Screen'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const FaceMorphScreen()),
                  );
                },
                child: const Text('Face Morph Screen'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const FaceMorphScreenDev()),
                  );
                },
                child: const Text('Face Morph Screen Develop'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const VideoUploadScreen()),
                  );
                },
                child: const Text('Video Upload Screen'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const VideoPlayerScreen()), // Add this line
                  );
                },
                child: const Text('Video Player Screen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
