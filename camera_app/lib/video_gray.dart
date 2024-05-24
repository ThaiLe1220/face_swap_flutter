import 'dart:async';
import 'dart:io';
import 'package:chewie/chewie.dart';
// import 'package:flutter_ffmpeg/ffmpeg_execution.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:native_opencv/native_opencv.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';

class VideoGray extends StatefulWidget {
  const VideoGray({super.key});
  @override
  VideoGrayState createState() => VideoGrayState();
}

class VideoGrayState extends State<VideoGray> {
  final List<File> _videoFiles = [];
  final List<File> _originalVideoFiles = [];
  final List<File> _extractedFrames = [];
  final List<File> _extractedFramesGray = [];
  // final FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();
  List<File> _files = [];
  var _imageHeight;
  int _currentIndex = 0;
  final ImagePicker _picker = ImagePicker();
  bool _isGrayscale = false;
  bool _isProcessing = false;
  VideoPlayerController? _controller;
  final NativeOpencv _opencv = NativeOpencv();

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);

      if (pickedFile != null) {
        File videoFile = File(pickedFile.path);
        setState(() {
          _videoFiles.add(videoFile);
          _originalVideoFiles.add(File(pickedFile.path));
          _currentIndex = _videoFiles.length - 1;
          _isGrayscale = false;
          _extractedFrames.clear();
          _extractedFramesGray.clear();
        });

        await _initializeVideoPlayer(_videoFiles[_currentIndex]);
        await _extractFrames(videoFile);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error picking video: $e');
      }
    }

    _isProcessing = false;
  }

  Future<void> _initializeVideoPlayer(File videoFile) async {
    _controller?.dispose();
    _controller = VideoPlayerController.file(videoFile)
      ..initialize().then((_) {
        setState(() {});
        _controller?.play();
      });
  }

  void listFilesInDirectory(directoryPath) async {
    try {
      final directory = await getTemporaryDirectory();
      final frameDir = Directory('${directory.path}/frames');

      if (await frameDir.exists()) {
        print(frameDir.path);
        setState(() {
          _files = frameDir
              .listSync()
              .whereType<File>()
              .toList();
        });

        if (_files.isEmpty) {
          print('Empty');
        } else {
          for (var file in _files) {
            print('Found file: ${file.path}');
          }
        }
      } else {
        print('Directory does not exist.');
      }
    } catch (e) {
      print('Error accessing directory: $e');
    }
  }

  Future<void> _extractFrames(File videoFile) async {
    try {
      final directory = await getTemporaryDirectory();
      final frameDir = Directory('${directory.path}/frames');
      if (await frameDir.exists()) {
        await frameDir.delete(recursive: true);
      }
      await frameDir.create();
      final framePattern = '${frameDir.path}/frame_%03d.png';
      String extractCommand = '-i ${videoFile.path} -vf fps=12 $framePattern';
      await FFmpegKit.execute(extractCommand).then((session) async {
        final returncode = await session.getReturnCode();
        if (ReturnCode.isSuccess(returncode)) {
          print('ffmpeg ok');
        } else {
          print('ffmpeg not ok');
        }
      });
      setState(() {
        _extractedFrames.clear();
        _extractedFrames.addAll(frameDir.listSync().whereType<File>().toList());
      });
      if (_extractedFrames.isNotEmpty) {
        await _getImageHeight(_extractedFrames[0]);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error extracting frames: $e');
      }
    }
  }

  Future<void> _getImageHeight(File imageFile) async {
    final image = Image.file(imageFile);
    final completer = Completer<ImageInfo>();
    final ImageStream stream = image.image.resolve(const ImageConfiguration());
    final listener = ImageStreamListener((ImageInfo info, bool _) {
      completer.complete(info);
    });
    stream.addListener(listener);
    final imageInfo = await completer.future;
    setState(() {
      _imageHeight = imageInfo.image.height.toDouble();
    });
    stream.removeListener(listener);
  }

  Future<void> _convertToGrayscale() async {
    if (_videoFiles.isEmpty || _isProcessing) return;
    _isProcessing = true;

    try {
      final directory = await getTemporaryDirectory();
      final frameDir = Directory('${directory.path}/frames');

      for (var frame in _extractedFrames) {
        String filename = 'gray_${path.basename(frame.path)}';
        String output = '${frameDir.path}/$filename';
        _opencv.convertToGrayScale(frame.path, output);
      }
      final outputPath = '${directory.path}/frames/${DateTime.now().millisecondsSinceEpoch}_gray.mp4';
      final command = '-framerate 30 -i ${frameDir.path}/frame_%03d.png -y ${outputPath}';
      await FFmpegKit.execute(command).then((session) async {
        final returncode = await session.getReturnCode();
        if (ReturnCode.isSuccess(returncode)) {
          print('ffmpeg ok');
        } else {
          print('ffmpeg not ok');
        }
      });
      // final outputPath = '/data/user/0/com.example.camera_app/cache/frames/temp.mp4';
      print(_videoFiles.length);
      final grayVideoFile = File(outputPath);
      if (await grayVideoFile.exists()) {
        print('Gray video created successfully!');
        // await _initializeVideoPlayer(grayVideoFile);
      } else {
        print('Gray video file does not exist.');
      }
      listFilesInDirectory(frameDir.path);
      setState(() {
        _extractedFramesGray.clear();
        _extractedFramesGray.addAll(
            frameDir.listSync()
                .whereType<File>()
                .where((file) => path.basename(file.path).startsWith('gray_'))
                .toList()
        );
        _isGrayscale = true;
      });

    } catch (e) {
      if (kDebugMode) {
        print('Error processing video: $e');
      }
      setState(() {
        _isGrayscale = false;
      });
    }

    _isProcessing = false;
  }

  void _showNextVideo() {
    if (_isProcessing) return;

    setState(() {
      if (_currentIndex < _videoFiles.length - 1) {
        _currentIndex++;
        _isGrayscale = false;
        _initializeVideoPlayer(_videoFiles[_currentIndex]);
      }
    });
  }

  void _showPreviousVideo() {
    if (_isProcessing) return;

    setState(() {
      if (_currentIndex > 0) {
        _currentIndex--;
        _isGrayscale = false;
        _initializeVideoPlayer(_videoFiles[_currentIndex]);
      }
    });
  }

  void _playPauseVideo() {
    if (_controller != null && _controller!.value.isInitialized) {
      setState(() {
        if (_controller!.value.isPlaying) {
          _controller?.pause();
        } else {
          _controller?.play();
        }
      });
    }
  }

  void _seekVideo(Duration position) {
    if (_controller != null && _controller!.value.isInitialized) {
      _controller?.seekTo(position);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Video'),
        toolbarHeight: 35.0,
      ),
      body: Center(
        child: _videoFiles.isEmpty
            ? const Text('No video selected.')
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: _controller != null && _controller!.value.isInitialized
                    ? AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                )
                    : const CircularProgressIndicator(),
              ),
            ),
            if (_controller != null && _controller!.value.isInitialized) ...[
              VideoProgressIndicator(
                _controller!,
                allowScrubbing: true,
                padding: const EdgeInsets.all(10.0),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                    onPressed: _playPauseVideo,
                  ),
                  Expanded(
                    child: Slider(
                      value: _controller!.value.position.inSeconds.toDouble(),
                      min: 0.0,
                      max: _controller!.value.duration.inSeconds.toDouble(),
                      onChanged: (value) {
                        _seekVideo(Duration(seconds: value.toInt()));
                      },
                    ),
                  ),
                ],
              ),
            ],
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 5.0), // Adjust the bottom padding as needed
                  child: SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.vertical,
                      itemCount: _extractedFrames.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.file(_extractedFrames[index]),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 5.0), // Adjust the top padding as needed
                  child: SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.vertical,
                      itemCount: _extractedFramesGray.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.file(_extractedFramesGray[index]),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
              child: ElevatedButton(
                onPressed: _convertToGrayscale,
                child: Text(_isGrayscale ? 'Revert to Normal' : 'Convert to Grayscale'),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickVideo,
        tooltip: 'Pick Video',
        child: const Icon(Icons.video_library),
      ),
    );
  }

}
