import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/controller/audio_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:com.jee.tag.whatagsapp/common/enums/message_enum.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/messages/message_utils.dart';

class AudioMessage extends StatefulWidget {
  final WidgetRef ref;
  final String chatId;
  final String messageId;

  // final double height;
  // final double width;
  // final String mimetype;
  // final Uint8List jpegThumbnail; // Use jpegThumbnail for the video thumbnail
  final int seconds;

  // final String? caption;

  const AudioMessage({
    Key? key,
    required this.ref,
    required this.chatId,
    required this.messageId,
    // required this.height,
    // required this.width,
    // required this.mimetype,
    // required this.jpegThumbnail,
    required this.seconds,
    // this.caption,
  }) : super(key: key);

  @override
  _VideoMessageState createState() => _VideoMessageState();
}

class _VideoMessageState extends State<AudioMessage> {
  bool _isDownloading = false;
  bool _videoDownloaded = false;

  String? get id => widget.messageId;

  AudioPlayer? get player => AudioController.getPlayer(id);
  File? audioFile;

  @override
  void initState() {
    super.initState();
    _checkAudioDownloaded();
  }

  _checkAudioDownloaded() async {
    final _localFilePath =
        await MessageUtils.getLocalFilePath(widget.messageId);

    if (_localFilePath != null) {
      audioFile = File(_localFilePath);
      if (await audioFile!.exists()) {
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
      _checkAudioDownloaded();
    } else {
      errorToast('Failed to download audio');
    }

    setState(() {
      _isDownloading = false;
    });
  }

  void errorToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  _initializeVideoController(String videoPath) {
    // player = AudioPlayer(playerId: widget.messageId);
    AudioController.addPlayer(id);
    player!.onPlayerStateChanged.listen((event) {
      if (mounted) {
        if (event == PlayerState.completed || event == PlayerState.stopped) {
          currentPosition = 0;
        }
        setState(() {});
      }
    });
    player!.eventStream.listen((event) {
      // print('eventStream ${event.position?.inSeconds}');
      if (event.position != null) {
        currentPosition = event.position!.inSeconds.toDouble();

        setState(() {});
      }
    });

    // playAudio();
    // _videoController = VideoPlayerController.file(File(videoPath))
    //   ..initialize().then((_) {
    //     setState(() {}); // Ensure the widget rebuilds with the video player.
    //   });
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
              playAudio();
            }
          },
          child: _buildVideoPlaceholder(),
        ),
      ],
    );
  }

  void playAudio() {
    if (audioFile != null) {
      if (isAudioPlaying) {
        player!.pause();
      } else if (player?.state == PlayerState.paused) {
        player!.resume();
      } else {
        AudioController.play(id, audioFile);
        // player!.play(BytesSource(videoFile!.readAsBytesSync()));
      } // if(result == 1){ //play success
      //   print("audio is playing.");
      // }else{
      //   print("Error while playing audio.");
      // }
    } else {
      errorToast('Audio file not found!');
    }
    setState(() {});
  }

  double currentPosition = 0;

  bool get isAudioPlaying => player?.state == PlayerState.playing;

  Widget _buildVideoPlaceholder() {
    return SizedBox(
      height: 50,
      width: 250,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // if (_isDownloading)
          //   const Center(
          //     child: CircularProgressIndicator(),
          //   )
          // else
          Row(
            children: [
              if (_videoDownloaded)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(isAudioPlaying ? Icons.stop : Icons.play_arrow,
                        color: Colors.white),
                    onPressed: playAudio,
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: _isDownloading
                      ? const CircularProgressIndicator()
                      : IconButton(
                          icon: const Icon(Icons.file_download,
                              color: Colors.white),
                          onPressed: _downloadAndPlayVideo,
                        ),
                ),
              Flexible(
                child: Slider(
                  max: widget.seconds.toDouble(),
                  value: currentPosition,
                  onChanged: (value) {
                    currentPosition = value;
                    player?.seek(Duration(seconds: value.toInt()));
                  },
                ),
              ),
            ],
          ),
          Positioned(
            right: 8.0,
            bottom: 0.0,
            child: Row(
              children: [
                const Icon(Icons.mic, color: Colors.white, size: 16),
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
      ),
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$hours:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    super.dispose();
    AudioController.removePlayer(id);
  }
}
