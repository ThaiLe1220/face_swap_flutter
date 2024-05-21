import 'dart:io'; // For file operations
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart'; // For accessing the file system
import 'package:video_player/video_player.dart';
import 'package:image/image.dart' as img;

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/f_3.mp4')
      ..initialize().then((_) {
        setState(
            () {}); // Ensure the first frame is shown after the video is initialized
        _controller.play();
      });
    _controller.addListener(() {
      setState(() {}); // Update the UI when the video position changes
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _convertVideoToGrayscale() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final directory = await getTemporaryDirectory();
      final outputPath = '${directory.path}/gray_video.mp4';
      final tempDir = Directory('${directory.path}/frames');
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }
      final List<File> frameFiles = [];

      // Extract and convert frames to grayscale
      while (_controller.value.isInitialized && !_controller.value.isPlaying) {
        final position = _controller.value.position;
        final frame = await _controller.captureFrame();
        final image = img.decodeImage(frame);

        if (image != null) {
          final grayscale = img.grayscale(image);
          final frameFile =
              File('${tempDir.path}/frame_${position.inMilliseconds}.png');
          frameFile.writeAsBytesSync(img.encodePng(grayscale));
          frameFiles.add(frameFile);
        }
      }

      // Combine frames into a video
      // Note: Combining frames into a video requires a library or tool that is not included in this example.
      // You can use ffmpeg or similar tools for this purpose.

      setState(() {
        _isProcessing = false;
      });

      // Play the new grayscale video
      _controller = VideoPlayerController.file(File(outputPath))
        ..initialize().then((_) {
          setState(
              () {}); // Ensure the first frame is shown after the video is initialized
          _controller.play();
        });
    } catch (e) {
      print('Error converting video: $e');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Player'),
      ),
      body: Center(
        child: _controller.value.isInitialized
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                  VideoProgressIndicator(
                    _controller,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Colors.blue,
                      bufferedColor: Colors.grey,
                      backgroundColor: Colors.black,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          _controller.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                        ),
                        onPressed: () {
                          setState(() {
                            _controller.value.isPlaying
                                ? _controller.pause()
                                : _controller.play();
                          });
                        },
                      ),
                      Text(
                        '${_formatDuration(_controller.value.position)} / ${_formatDuration(_controller.value.duration)}',
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _isProcessing ? null : _convertVideoToGrayscale,
                    child: const Text('Convert to Grayscale'),
                  ),
                ],
              )
            : const CircularProgressIndicator(),
      ),
    );
  }

  String _formatDuration(Duration position) {
    final String minutes =
        position.inMinutes.remainder(60).toString().padLeft(2, '0');
    final String seconds =
        position.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
