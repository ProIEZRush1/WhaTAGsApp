import 'dart:io';
import 'dart:typed_data';

import 'package:com.jee.tag.whatagsapp/common/enums/message_enum.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/messages/message_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';

class ImageMessage extends StatefulWidget {
  final WidgetRef ref;
  final String chatId;
  final String messageId;
  final double height;
  final double width;
  final String mimetype;
  final Uint8List jpegThumbnail;
  final String? caption;

  const ImageMessage(
      {Key? key,
      required this.ref,
      required this.chatId,
      required this.messageId,
      required this.height,
      required this.width,
      required this.mimetype,
      required this.jpegThumbnail,
      this.caption})
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
  late String? caption;

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
    caption = widget.caption;

    _checkImageDownloaded();
  }

  _checkImageDownloaded() async {
    _localFilePath = await MessageUtils.getLocalFilePath(messageId);
    if (_localFilePath != null) {
      File imageFile = File(_localFilePath!);
      if (await imageFile.exists()) {
        setState(() {
          _imageDownloaded = true;
        });
      } else {
        setState(() {
          _imageDownloaded = false;
        });
      }
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            if (_imageDownloaded) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return Dialog(
                      backgroundColor: Colors.transparent,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: SizedBox(
                              width: width / 3,
                              height: height / 3,
                              child: PhotoView(
                                imageProvider: FileImage(File(_localFilePath!)),
                                minScale: PhotoViewComputedScale.contained,
                                maxScale: PhotoViewComputedScale.covered * 2,
                                backgroundDecoration: const BoxDecoration(
                                    color: Colors.transparent),
                              ),
                            ),
                          ),
                        ],
                      ));
                },
              );
            }
          },
          child: _imageDownloaded
              ? Image.file(
                  File(_localFilePath!),
                  fit: BoxFit.cover,
                  height: height / 3,
                  width: width / 3,
                )
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.memory(
                      jpegThumbnail,
                      fit: BoxFit.cover,
                      height: height / 3,
                      width: width / 3,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.file_download,
                            color: Colors.green),
                        onPressed: _downloadAndDisplayImage,
                      ),
                    ),
                  ],
                ),
        ),
        if (caption != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              caption!,
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
}
