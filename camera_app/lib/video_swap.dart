import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:native_opencv/native_opencv.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'utils/face_morph_utils.dart';

class VideoSwap extends StatefulWidget {
  const VideoSwap({super.key});
  @override
  VideoSwapState createState() => VideoSwapState();
}

class VideoSwapState extends State<VideoSwap> {
  final List<File> _videoFiles = [];
  final List<File> _originalVideoFiles = [];
  final List<File> _extractedFrames = [];
  final List<File> _extractedFramesGray = [];
  List<File> _files = [];
  var _imageHeight;
  int _currentIndex = 0;
  final ImagePicker _picker = ImagePicker();
  bool _isTargetPicked = false;
  bool _isProcessing = false;
  VideoPlayerController? _controller;
  VideoPlayerController? _controller2;
  final NativeOpencv _opencv = NativeOpencv();

  File? _image1;
  File? _image2;
  String? _outputImagePath;
  List<Point<double>> _contours1 = [];
  List<Point<double>> _contours2 = [];
  List<int> _delaunayTriangles = [];
  late ui.Image _imageInfo1;
  late ui.Image _imageInfo2;

  // Add variables to store the elapsed time
  Duration? _pickImage1Time;
  Duration? _pickImage2Time;
  Duration? _detectFaces1Time;
  Duration? _detectFaces2Time;
  Duration? _morphImageTime;
  Duration? _delaunayTrianglesTime;

  final _fps = 24;
  double _progress = 0.0;
  bool _showProgress = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void getImageInfo(File imageFile) async {
    Uint8List bytes = await imageFile.readAsBytes();
    ui.Codec codec = await ui.instantiateImageCodec(bytes);
    ui.FrameInfo frameInfo = await codec.getNextFrame();
    _imageInfo1 = frameInfo.image;
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
          _isTargetPicked = false;
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

  Future<void> _initializeVideoPlayer2(File videoFile) async {
    _controller2?.dispose();
    _controller2 = VideoPlayerController.file(videoFile)
      ..initialize().then((_) {
        setState(() {});
        _controller2?.play();
      });
  }

  Future<void> listFilesInDirectory(directoryPath) async {
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
        await listFilesInDirectory(frameDir);
      }
      await frameDir.create();
      final framePattern = '${frameDir.path}/frame_%03d.png';
      String extractCommand = '-i ${videoFile.path} -vf fps=$_fps $framePattern';
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

  Future<void> _swapFrame1() async {
    if (_videoFiles.isEmpty || _isProcessing) return;
    _isProcessing = true;

    try {
      final directory = await getTemporaryDirectory();
      final frameDir = Directory('${directory.path}/frames');
      if (_contours2.isNotEmpty) {
        print('_contours2 is NOT empty!');
      } else {
        print('_contours2 is empty!');
      }
      for (var frame in _extractedFrames) {
        String filename = 'swap_${path.basename(frame.path)}';
        String output = '${frameDir.path}/$filename';
        File _image1 = File(frame.path);
        getImageInfo(_image1);
        await detectFacesWithTiming(_image1, 1, (contours) {
          setState(() {
            _contours1 = contours;
            if (_contours1.isNotEmpty && _contours2.isNotEmpty) {
              computeCorrespondences(_contours1, _contours2, (correspondences) {
                computeDelaunayWithTime(
                    _contours1, _imageInfo1, (delaunayTriangles) {
                  setState(() {
                    _delaunayTriangles = delaunayTriangles;
                  });
                }, (elapsed) {
                  setState(() {
                    _detectFaces1Time = elapsed;
                  });
                });
              });
            }
          });
        }, (elapsed) {});
        print('time detect face ${frame.path}: $_detectFaces1Time');
        await morphImagesFrame(
            output,
            _image1,
            _image2,
            _contours1,
            _contours2,
            _delaunayTriangles,
            0.5, (outputPath) {
          setState(() {
            _outputImagePath = outputPath;
            print('_outputImagePath $_outputImagePath');
          });
        }, (a) {});
      }

      final framePattern = '${frameDir.path}/swap_frame_%03d.png';
      final outputVideoPath = '${frameDir.path}/output.mp4';
      String extractCommand = '-framerate $_fps  -pix_fmt yuv420p -i $framePattern $outputVideoPath';
      await FFmpegKit.execute(extractCommand).then((session) async {
        final returncode = await session.getReturnCode();
        if (ReturnCode.isSuccess(returncode)) {
          print('ffmpeg ok');
          _initializeVideoPlayer2(File(outputVideoPath));
        } else {
          print('ffmpeg not ok');
        }
      });

      listFilesInDirectory(frameDir.path);
      setState(() {
        _extractedFramesGray.clear();
        _extractedFramesGray.addAll(
            frameDir.listSync()
                .whereType<File>()
                .where((file) => path.basename(file.path).startsWith('swap_'))
                .toList()
        );
      });

    } catch (e) {
      if (kDebugMode) {
        print('Error swapping video: $e');
      }
      setState(() {
        _isTargetPicked = false;
      });
    }

    _isProcessing = false;
  }

  Future<void> _swapFrame() async {
    if (_videoFiles.isEmpty || _isProcessing) return;
    _isProcessing = true;
    setState(() {
      _progress = 0.0;
      _showProgress = true;
    });

    try {
      final directory = await getTemporaryDirectory();
      final frameDir = Directory('${directory.path}/frames');
      if (_contours2.isNotEmpty) {
        print('_contours2 is NOT empty!');
      } else {
        print('_contours2 is empty!');
      }
      int totalFrames = _extractedFrames.length;
      for (var i = 0; i < totalFrames; i++) {
        var frame = _extractedFrames[i];
        String filename = 'swap_${path.basename(frame.path)}';
        String output = '${frameDir.path}/$filename';
        File _image1 = File(frame.path);
        getImageInfo(_image1);
        await detectFacesWithTiming(_image1, 1, (contours) {
          setState(() {
            _contours1 = contours;
            if (_contours1.isNotEmpty && _contours2.isNotEmpty) {
              computeCorrespondences(_contours1, _contours2, (correspondences) {
                computeDelaunayWithTime(
                    _contours1, _imageInfo1, (delaunayTriangles) {
                  setState(() {
                    _delaunayTriangles = delaunayTriangles;
                  });
                }, (elapsed) {
                  setState(() {
                    _detectFaces1Time = elapsed;
                  });
                });
              });
            }
          });
        }, (elapsed) {});
        print('time detect face ${frame.path}: $_detectFaces1Time');
        await morphImagesFrame(
            output,
            _image1,
            _image2,
            _contours1,
            _contours2,
            _delaunayTriangles,
            0.5, (outputPath) {
          setState(() {
            _outputImagePath = outputPath;
            print('_outputImagePath $_outputImagePath');
          });
        }, (a) {});

        // Update the progress
        setState(() {
          _progress = (i + 1) / totalFrames;
        });
      }

      final framePattern = '${frameDir.path}/swap_frame_%03d.png';
      final outputVideoPath = '${frameDir.path}/output.mp4';
      String extractCommand = '-framerate $_fps  -pix_fmt yuv420p -i $framePattern $outputVideoPath';
      await FFmpegKit.execute(extractCommand).then((session) async {
        final returncode = await session.getReturnCode();
        if (ReturnCode.isSuccess(returncode)) {
          print('ffmpeg ok');
          _initializeVideoPlayer2(File(outputVideoPath));
        } else {
          print('ffmpeg not ok');
        }
      });

      listFilesInDirectory(frameDir.path);
      setState(() {
        _extractedFramesGray.clear();
        _extractedFramesGray.addAll(
            frameDir.listSync()
                .whereType<File>()
                .where((file) => path.basename(file.path).startsWith('swap_'))
                .toList()
        );
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error swapping video: $e');
      }
      setState(() {
        _isTargetPicked = false;
      });
    }

    setState(() {
      _isProcessing = false;
      _showProgress = false;
    });
  }

  void _showNextVideo() {
    if (_isProcessing) return;

    setState(() {
      if (_currentIndex < _videoFiles.length - 1) {
        _currentIndex++;
        _isTargetPicked = false;
        _initializeVideoPlayer(_videoFiles[_currentIndex]);
      }
    });
  }

  void _showPreviousVideo() {
    if (_isProcessing) return;

    setState(() {
      if (_currentIndex > 0) {
        _currentIndex--;
        _isTargetPicked = false;
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

  void _playPauseVideo2() {
    if (_controller2 != null && _controller2!.value.isInitialized) {
      setState(() {
        if (_controller2!.value.isPlaying) {
          _controller2?.pause();
        } else {
          _controller2?.play();
        }
      });
    }
  }


  void _seekVideo(Duration position) {
    if (_controller != null && _controller!.value.isInitialized) {
      _controller?.seekTo(position);
    }
  }

  void _seekVideo2(Duration position) {
    if (_controller2 != null && _controller2!.value.isInitialized) {
      _controller2?.seekTo(position);
    }
  }

  void _onImagePicked(File imageFile, ui.Image imageInfo, int imageNumber) {
    setState(() {
      if (imageNumber == 1) {
        _image1 = imageFile;
        _imageInfo1 = imageInfo;
        _contours1.clear(); // Clear previous contours for image1
      } else if (imageNumber == 2) {
        _image2 = imageFile;
        _imageInfo2 = imageInfo;
        _contours2.clear();
        _isTargetPicked = true;// Clear previous contours for image2
      }
      _delaunayTriangles.clear(); // Clear previous Delaunay triangles
      _outputImagePath = null; // Clear the morphed image path
    });
    // Detect faces after image is picked
    detectFacesWithTiming(imageFile, imageNumber, (contours) {
      setState(() {
        if (imageNumber == 1) {
          _contours1 = contours;
        } else {
          _contours2 = contours;
        }

        if (_contours1.isNotEmpty && _contours2.isNotEmpty) {
          computeCorrespondences(_contours1, _contours2, (correspondences) {
            computeDelaunayWithTime(
                _contours1, _imageInfo1, (delaunayTriangles) {
              setState(() {
                _delaunayTriangles = delaunayTriangles;
              });
            }, (elapsed) {
              setState(() {
                _detectFaces1Time = elapsed;
              });
            });
          });
        }
      });
    }, (elapsed) {
      setState(() {
        if (imageNumber == 1) {
          _detectFaces1Time = elapsed;
        } else {
          _detectFaces2Time = elapsed;
        }
      });
    });
  }

  Widget _buildImage(File imageFile, ui.Image imageInfo) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double scaleX = constraints.maxWidth / imageInfo.width;
        double scaleY = constraints.maxHeight / imageInfo.height;
        double scale = min(scaleX, scaleY);
        return SizedBox(
          width: imageInfo.width * scale,
          height: imageInfo.height * scale,
          child: Image.file(imageFile),
        );
      },
    );
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
            : ListView(
          children: [
            if (_controller != null && _controller!.value.isInitialized)
              ...[
                Center(
                  child: AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  ),
                ),
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
            if (_controller2 != null && _controller2!.value.isInitialized)
              ...[
                Center(
                  child: AspectRatio(
                    aspectRatio: _controller2!.value.aspectRatio,
                    child: VideoPlayer(_controller2!),
                  ),
                ),
                VideoProgressIndicator(
                  _controller2!,
                  allowScrubbing: true,
                  padding: const EdgeInsets.all(10.0),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        _controller2!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                      ),
                      onPressed: _playPauseVideo2,
                    ),
                    Expanded(
                      child: Slider(
                        value: _controller2!.value.position.inSeconds.toDouble(),
                        min: 0.0,
                        max: _controller2!.value.duration.inSeconds.toDouble(),
                        onChanged: (value) {
                          _seekVideo2(Duration(seconds: value.toInt()));
                        },
                      ),
                    ),
                  ],
                ),
              ],
            _image2 == null
                ? const Text('No image selected.')
                : _buildImage(_image2!, _imageInfo2),
            if (_showProgress)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('Processing frames... ${(_progress * 100).toStringAsFixed(2)}%'),
                    SizedBox(height: 20),
                    LinearProgressIndicator(value: _progress),
                  ],
                ),
              ),
            // Column(
            //   children: [
            //     Padding(
            //       padding: const EdgeInsets.only(bottom: 5.0, left: 50.0),
            //       child: SizedBox(
            //         height: 500,
            //         child: ListView.builder(
            //           scrollDirection: Axis.vertical,
            //           itemCount: _extractedFrames.length,
            //           itemBuilder: (context, index) {
            //             return Container(
            //               margin: const EdgeInsets.symmetric(vertical: 10.0),
            //               child: Image.file(_extractedFrames[index]),
            //             );
            //           },
            //         ),
            //       ),
            //     ),
            //     Padding(
            //       padding: const EdgeInsets.only(bottom: 5.0, left: 50.0),
            //       child: SizedBox(
            //         height: 500,
            //         child: ListView.builder(
            //           scrollDirection: Axis.vertical,
            //           itemCount: _extractedFramesGray.length,
            //           itemBuilder: (context, index) {
            //             return Container(
            //               margin: const EdgeInsets.symmetric(vertical: 10.0),
            //               child: Image.file(_extractedFramesGray[index]),
            //             );
            //           },
            //         ),
            //       ),
            //     ),
            //   ],
            // ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
              child: ElevatedButton(
                onPressed: _isTargetPicked ? _swapFrame : null,
                child: Text(
                  _isTargetPicked ? 'Begin Swapping!' : 'Please Pick Target Image',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () =>
                  pickImage(
                    2,
                        (imageFile, imageInfo) => _onImagePicked(imageFile, imageInfo, 2),
                        (elapsed) {
                      setState(() {
                        _pickImage2Time = elapsed;
                      });
                    },
                    detectFacesWithTiming,
                        (elapsed) {
                      setState(() {
                        _detectFaces2Time = elapsed;
                      });
                    },
                  ),
              child: const Text('Pick Target Image'),
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

