import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit.dart';

class VideoUploadScreen extends StatefulWidget {
  const VideoUploadScreen({super.key});

  @override
  _VideoUploadScreenState createState() => _VideoUploadScreenState();
}

class _VideoUploadScreenState extends State<VideoUploadScreen> {
  VideoPlayerController? _controller;
  String? _videoPath;
  List<File> _frames = [];
  bool _showFrames = false;

  @override
  void initState() {
    super.initState();
    _controller?.addListener(() {
      setState(() {}); // Update the UI on controller updates
    });
  }

  @override
  void dispose() {
    _controller?.removeListener(() {});
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null && result.files.single.path != null) {
      _videoPath = result.files.single.path;
      // Dispose the previous controller if exists
      _controller?.dispose();
      _controller = VideoPlayerController.file(File(_videoPath!))
        ..initialize().then((_) {
          setState(() {});
          _controller?.play();
          _controller?.addListener(() {
            setState(() {}); // Update the UI on controller updates
          });
        });
      await _extractFrames();
    }
  }

  Future<void> _extractFrames() async {
    final directory = await getTemporaryDirectory();
    final outputPath = directory.path;

    final command = '-i $_videoPath -vf fps=30 $outputPath/frame_%03d.png';
    await FFmpegKit.execute(command);

    final frameFiles = Directory(outputPath)
        .listSync()
        .where((file) => path.extension(file.path) == '.png')
        .map((file) => File(file.path))
        .toList();

    setState(() {
      _frames = frameFiles;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return [if (duration.inHours > 0) hours, minutes, seconds].join(':');
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        IconButton(
          icon: Icon(_controller?.value.isPlaying ?? false
              ? Icons.pause
              : Icons.play_arrow),
          onPressed: () {
            setState(() {
              if (_controller?.value.isPlaying ?? false) {
                _controller?.pause();
              } else {
                _controller?.play();
              }
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.replay_10),
          onPressed: () {
            final currentPosition =
                _controller?.value.position ?? Duration.zero;
            final newPosition = currentPosition - const Duration(seconds: 10);
            _controller?.seekTo(
                newPosition > Duration.zero ? newPosition : Duration.zero);
          },
        ),
        IconButton(
          icon: const Icon(Icons.forward_10),
          onPressed: () {
            final currentPosition =
                _controller?.value.position ?? Duration.zero;
            final newPosition = currentPosition + const Duration(seconds: 10);
            final duration = _controller?.value.duration ?? Duration.zero;
            _controller
                ?.seekTo(newPosition < duration ? newPosition : duration);
          },
        ),
      ],
    );
  }

  Widget _buildSlider() {
    return _controller != null && _controller!.value.isInitialized
        ? Column(
            children: [
              Slider(
                value: _controller!.value.position.inSeconds.toDouble(),
                max: _controller!.value.duration.inSeconds.toDouble(),
                onChanged: (value) {
                  setState(() {
                    _controller?.seekTo(Duration(seconds: value.toInt()));
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(_controller!.value.position)),
                    Text(_formatDuration(_controller!.value.duration)),
                  ],
                ),
              ),
            ],
          )
        : const SizedBox.shrink();
  }

  Widget _buildFrameGallery() {
    return _showFrames
        ? _frames.isNotEmpty
            ? GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4.0,
                  mainAxisSpacing: 4.0,
                ),
                itemCount: _frames.length,
                itemBuilder: (context, index) {
                  return Image.file(_frames[index]);
                },
              )
            : const Text('No frames extracted.')
        : const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload and Play Video'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (_controller != null && _controller!.value.isInitialized)
                AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                )
              else
                const Text('No video selected.'),
              const SizedBox(height: 16),
              _buildSlider(),
              _buildControlButtons(),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickVideo,
                child: const Text('Upload Video'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showFrames = !_showFrames;
                  });
                },
                child: Text(_showFrames ? 'Hide Frames' : 'Show Frames'),
              ),
              const SizedBox(height: 16),
              _buildFrameGallery(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
