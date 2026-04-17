import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'file_stub.dart' if (dart.library.io) 'dart:io' show File;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: VideoPlayerScreen());
  }
}

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  VideoPlayerScreenState createState() => VideoPlayerScreenState();
}

class VideoPlayerScreenState extends State<VideoPlayerScreen> {
  final ImagePicker _picker = ImagePicker();
  VideoPlayerController? _controller;
  XFile? _videoFile;
  double _speed = 1.0;
  bool _showCount = false;
  int _count = 0;
  Timer? _timer;

  @override
  void dispose() {
    _controller?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final XFile? result = await _picker.pickVideo(source: ImageSource.gallery);
    if (result != null) {
      _videoFile = result;
      _count = 0;
      _stopCount();
      await _initializeController();
    }
  }

  Future<void> _initializeController() async {
    if (_videoFile != null) {
      _controller?.dispose();

      if (kIsWeb) {
        final bytes = await _videoFile!.readAsBytes();
        final mimeType = _videoMimeType(_videoFile!.name);
        final uri = Uri.dataFromBytes(bytes, mimeType: mimeType);
        _controller = VideoPlayerController.networkUrl(uri);
      } else {
        _controller = VideoPlayerController.file(
          File(_videoFile!.path) as dynamic,
        );
      }

      _controller!
          .initialize()
          .then((_) {
            setState(() {});
          })
          .catchError((error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Video initialization failed: $error')),
              );
            }
          });
    }
  }

  String _videoMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.mov')) return 'video/quicktime';
    if (lower.endsWith('.webm')) return 'video/webm';
    if (lower.endsWith('.ogg')) return 'video/ogg';
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.m4v')) return 'video/x-m4v';
    return 'video/mp4';
  }

  void _playPause() {
    if (_controller != null) {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _stopCount();
      } else {
        _count = 0;
        _controller!.play();
        if (_showCount) _startCount();
      }
      setState(() {});
    }
  }

  void _setSpeed(double speed) {
    setState(() {
      _speed = speed;
      _controller?.setPlaybackSpeed(speed);
    });
  }

  void _toggleCount() {
    setState(() {
      _showCount = !_showCount;
      if (_showCount && _controller != null && _controller!.value.isPlaying) {
        _startCount();
      } else {
        _stopCount();
      }
    });
  }

  void _startCount() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _count++;
      });
    });
  }

  void _stopCount() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dance Practice App')),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_controller != null && _controller!.value.isInitialized)
                  AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  )
                else
                  Center(child: Text('Select a video')),
                if (_showCount)
                  Positioned(
                    top: 20,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      color: Colors.black54,
                      child: Text(
                        _count.toString(),
                        style: TextStyle(color: Colors.white, fontSize: 24),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(onPressed: _pickVideo, child: Text('Pick Video')),
              ElevatedButton(
                onPressed: _playPause,
                child: Text(
                  _controller != null && _controller!.value.isPlaying
                      ? 'Pause'
                      : 'Play',
                ),
              ),
              DropdownButton<double>(
                value: _speed,
                items: [0.5, 0.75, 1.0, 1.25, 1.5].map((double value) {
                  return DropdownMenuItem<double>(
                    value: value,
                    child: Text('${value}x'),
                  );
                }).toList(),
                onChanged: (double? newValue) {
                  if (newValue != null) _setSpeed(newValue);
                },
              ),
              Row(
                children: [
                  Text('Show Count'),
                  Switch(
                    value: _showCount,
                    onChanged: (bool value) {
                      _toggleCount();
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
