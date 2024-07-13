import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:video_compress/video_compress.dart';

class AddEditVideo extends StatefulWidget {
  final String wordVideo;
  final ValueChanged<String> onVideoChanged;

  const AddEditVideo({
    required this.wordVideo,
    required this.onVideoChanged,
  });

  @override
  _AddEditVideoState createState() => _AddEditVideoState();
}

class _AddEditVideoState extends State<AddEditVideo> {
  late String _currentVideo;
  VideoPlayerController? _videoController;
  bool _isLoading = false;
  Subscription? _subscription;

  @override
  void initState() {
    super.initState();
    _currentVideo = widget.wordVideo;
    if (_currentVideo.isNotEmpty) {
      _initializeVideoPlayer(File(_currentVideo));
    }
  }

  void _initializeVideoPlayer(File videoFile) {
    _videoController = VideoPlayerController.file(videoFile)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickVideo(source: source);

      if (pickedFile != null) {
        final videoDuration = await _getVideoDuration(File(pickedFile.path));
        if (videoDuration > const Duration(seconds: 10)) {
          _showErrorDialog('The selected video exceeds the 10-second limit.');
          return;
        }

        setState(() {
          _isLoading = true;
        });

        File? processedVideo;
        if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android)) {
          processedVideo = await _compressVideo(File(pickedFile.path));
        } else {
          processedVideo = File(pickedFile.path);
        }

        setState(() {
          _currentVideo = processedVideo?.path ?? pickedFile.path;
          _initializeVideoPlayer(File(_currentVideo));
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error picking video: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Duration> _getVideoDuration(File videoFile) async {
    final videoPlayerController = VideoPlayerController.file(videoFile);
    await videoPlayerController.initialize();
    final duration = videoPlayerController.value.duration;
    videoPlayerController.dispose();
    return duration;
  }

  Future<File?> _compressVideo(File videoFile) async {
    try {
      _subscription = VideoCompress.compressProgress$.subscribe((progress) {
        setState(() {
          _isLoading = true;
        });
        if (progress == 100) {
          _subscription?.unsubscribe();
        }
      });

      final info = await VideoCompress.compressVideo(
        videoFile.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
        frameRate: 30,
        duration: 10,
      );

      return info?.file;
    } catch (e) {
      print('Video compression error: $e');
      _subscription?.unsubscribe();
      return null;
    }
  }

  void _clearVideo() {
    setState(() {
      _currentVideo = '';
      _videoController?.dispose();
      _videoController = null;
    });
  }

  void _confirmClearVideo() {
    if (_currentVideo.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm'),
          content: const Text('Do you want to discard the selected video?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _clearVideo();
                Navigator.pop(context); // Close the Select Video dialog
              },
              child: const Text('Yes'),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _confirmSaveVideo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm'),
        content: const Text('Do you want to save this video?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              _saveVideo();
              Navigator.pop(context); // Close the confirmation dialog
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _saveVideo() {
    widget.onVideoChanged(_currentVideo);
    Navigator.pop(context); // Close the Select Video dialog
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _subscription?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: AlertDialog(
        title: const Text('Select Video'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Container(
                height: 150,
                width: double.infinity,
                color: Colors.grey[300],
                child: _currentVideo.isEmpty
                    ? const Center(child: Text('No video selected'))
                    : kIsWeb
                        ? const Text('Video preview not available on web') // Placeholder for web
                        : _videoController != null && _videoController!.value.isInitialized
                            ? AspectRatio(
                                aspectRatio: 16 / 9, // Set the aspect ratio to 16:9
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: <Widget>[
                                    VideoPlayer(_videoController!),
                                    VideoProgressIndicator(_videoController!, allowScrubbing: true),
                                    _ControlsOverlay(controller: _videoController!),
                                  ],
                                ),
                              )
                            : const Center(child: CircularProgressIndicator()),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (_currentVideo.isNotEmpty)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _confirmClearVideo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _pickVideo(ImageSource.camera),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _pickVideo(ImageSource.gallery),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Gallery'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _confirmClearVideo,
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _confirmSaveVideo,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({Key? key, required this.controller}) : super(key: key);

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 50),
          reverseDuration: const Duration(milliseconds: 200),
          child: controller.value.isPlaying
              ? const SizedBox.shrink()
              : Container(
                  color: Colors.black26,
                  child: const Center(
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 100.0,
                      semanticLabel: 'Play',
                    ),
                  ),
                ),
        ),
        GestureDetector(
          onTap: () {
            controller.value.isPlaying ? controller.pause() : controller.play();
          },
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: VideoProgressIndicator(controller, allowScrubbing: true),
        ),
      ],
    );
  }
}

void showAddEditVideoDialog(BuildContext context, String wordVideo, ValueChanged<String> onVideoChanged) {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevent dismissing by tapping outside
    builder: (context) => AddEditVideo(wordVideo: wordVideo, onVideoChanged: onVideoChanged),
  );
}
