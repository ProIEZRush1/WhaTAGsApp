import 'dart:io';
import 'dart:typed_data';

import 'package:com.jee.tag.whatagsapp/common/enums/message_enum.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/messages/message_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

class ImageMessage extends StatefulWidget {
  final WidgetRef ref;
  final String chatId;
  final String messageId;
  final double height;
  final double width;
  final String mimetype;
  final Uint8List jpegThumbnail;

  const ImageMessage(
      {Key? key,
      required this.ref,
      required this.chatId,
      required this.messageId,
      required this.height,
      required this.width,
      required this.mimetype,
      required this.jpegThumbnail})
      : super(key: key);

  @override
  _ImageMessageState createState() => _ImageMessageState();
}

class _ImageMessageState extends State<ImageMessage> {
  bool _imageDownloaded = false;
  String? _localFilePath;

  final double maxPreviewHeight = 150.0;
  final double maxPreviewWidth = 150.0;

  late WidgetRef ref;
  late String chatId;
  late String messageId;
  late double height;
  late double width;
  late String mimetype;
  late Uint8List jpegThumbnail;

  @override
  void initState() {
    super.initState();

    ref = widget.ref;
    chatId = widget.chatId;
    messageId = widget.messageId;
    height = widget.height;
    width = widget.width;
    mimetype = widget.mimetype;
    jpegThumbnail = widget.jpegThumbnail;

    _checkImageDownloaded();
  }

  _checkImageDownloaded() async {
    _localFilePath = await MessageUtils.getLocalFilePath(messageId);
    if (_localFilePath != null) {
      setState(() {
        _imageDownloaded = true;
      });
    }
  }

  _downloadAndDisplayImage() async {
    // Use a callback to get the download progress
    bool success = await MessageUtils.downloadAndSaveFile(
        context, ref, chatId, messageId, MessageEnum.image);
    if (success) {
      _checkImageDownloaded();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to download image')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double previewWidth, previewHeight;

    // Calculate the aspect ratio of the original image
    double aspectRatio = height / width;

    if (width > height) {
      // Landscape or square image
      previewWidth = maxPreviewWidth;
      previewHeight = previewWidth * aspectRatio;
    } else {
      // Portrait image
      previewHeight = maxPreviewHeight;
      previewWidth = previewHeight / aspectRatio;
    }

    if (_imageDownloaded) {
      return Image.file(File(_localFilePath!));
    } else {
      return Stack(
        children: [
          Image.memory(
            jpegThumbnail,
            fit: BoxFit.cover,
            height: previewHeight,
            width: previewWidth,
            errorBuilder: (BuildContext context, Object exception,
                StackTrace? stackTrace) {
              print('Error Handler: $exception');
              return const Text('Error occurred!');
            },
          ),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.file_download),
                  onPressed: _downloadAndDisplayImage,
                ),
              ],
            ),
          ),
        ],
      );
    }
  }
}
