import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:com.jee.tag.whatagsapp/common/enums/message_enum.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/messages/message_utils.dart';

class VideoMessage extends StatefulWidget {
  final WidgetRef ref;
  final String chatId;
  final String messageId;
  final double height;
  final double width;
  final String mimetype;
  final Uint8List jpegThumbnail; // Use jpegThumbnail for the video thumbnail
  final int seconds;
  final String? caption;

  const VideoMessage({
    Key? key,
    required this.ref,
    required this.chatId,
    required this.messageId,
    required this.height,
    required this.width,
    required this.mimetype,
    required this.jpegThumbnail,
    required this.seconds,
    this.caption,
  }) : super(key: key);

  @override
  State<VideoMessage> createState() => _VideoMessageState();
}

class _VideoMessageState extends State<VideoMessage> {
  bool _isDownloading = false;
  bool _videoDownloaded = false;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _checkVideoDownloaded();
  }

  _checkVideoDownloaded() async {
    final _localFilePath =
        await MessageUtils.getLocalFilePath(widget.messageId);

    if (_localFilePath != null) {
      File videoFile = File(_localFilePath);
      if (await videoFile.exists()) {
        _videoDownloaded = true;
        refresh();
        _initializeVideoController(_localFilePath);
      } else {
        _videoDownloaded = false;
        refresh();
      }
    }
  }

  refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  _downloadAndPlayVideo() async {
    setState(() {
      _isDownloading = true;
    });

    bool success = await MessageUtils.downloadAndSaveFile(
      context,
      widget.ref,
      widget.chatId,
      widget.messageId,
      MessageUtils.getFileExtension(MessageEnum.video),
    );

    if (success) {
      _checkVideoDownloaded();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to download video')),
      );
    }

    setState(() {
      _isDownloading = false;
    });
  }

  _initializeVideoController(String videoPath) {
    _videoController = VideoPlayerController.file(File(videoPath))
      ..initialize().then((_) {
        refresh(); // Ensure the widget rebuilds with the video player.
      });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            if (_videoDownloaded) {
              _playVideo();
            }
          },
          child: _videoDownloaded
              ? _buildDownloadedVideo()
              : _buildVideoPlaceholder(),
        ),
        if (widget.caption != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              widget.caption!,
              textAlign: TextAlign.left,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16.0,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDownloadedVideo() {
    if (_videoController != null) {
      return Center(
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: Stack(
            children: [
              VideoPlayer(_videoController!),
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow),
                ),
              )
            ],
          ),
        ),
      );
    } else {
      return Container(); // Return an empty container if the video controller is not initialized yet.
    }
  }

  Widget _buildVideoPlaceholder() {
    return Stack(
      alignment: Alignment.center,
      children: [
        ///place holder loader show before video is load
        const Center(
          child: CircularProgressIndicator(),
        ),
        // Display the video thumbnail before downloading
        widget.jpegThumbnail.isNotEmpty
            ? Image.memory(
                widget.jpegThumbnail,
                fit: BoxFit.cover,
                height: widget.height / 2,
                width: widget.width,
                // Set the width to match the preview
              )
            : Image.asset(
                "assets/blurred.jpg",
                fit: BoxFit.cover,
                height: widget.height / 2,
                width: widget.width, // Set the width to match the preview
              ),
        if (_isDownloading)
          const Center(
            child: CircularProgressIndicator(),
          )
        else
          GestureDetector(
            onTap: () {
              if (_videoDownloaded) {
                _playVideo();
              }
            },
            child: SizedBox(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.file_download, color: Colors.white),
                  onPressed: _downloadAndPlayVideo,
                ),
              ),
            ),
          ),
        Positioned(
          right: 8.0,
          bottom: 8.0,
          child: Row(
            children: [
              const Icon(Icons.videocam, color: Colors.white, size: 16),
              const SizedBox(width: 4.0),
              Text(
                _formatDuration(widget.seconds),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$hours:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _playVideo() {
    if (_videoController != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, state) {
            return Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    _videoController!.pause();
                    Navigator.of(context).pop();
                  },
                ),
                elevation: 0,
              ),
              body: Center(
                child: AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  if (_videoController!.value.isPlaying) {
                    _videoController!.pause();
                  } else {
                    _videoController!.play();
                  }
                  state(() {});
                },
                child: Icon(
                  _videoController!.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                ),
              ),
            );
          });
        },
      );
      _videoController!.play();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _videoController?.dispose();
  }
}
