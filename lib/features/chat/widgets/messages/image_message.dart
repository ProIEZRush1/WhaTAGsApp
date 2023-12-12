import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:com.jee.tag.whatagsapp/common/enums/message_enum.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/messages/message_utils.dart';

class ImageMessage extends StatefulWidget {
  final WidgetRef ref;
  final String chatId;
  final String messageId;
  final double height;
  final double width;
  final String mimetype;
  final Uint8List jpegThumbnail;
  final String? caption;

  const ImageMessage({
    Key? key,
    required this.ref,
    required this.chatId,
    required this.messageId,
    required this.height,
    required this.width,
    required this.mimetype,
    required this.jpegThumbnail,
    this.caption,
  }) : super(key: key);

  @override
  _ImageMessageState createState() => _ImageMessageState();
}

class _ImageMessageState extends State<ImageMessage> {
  bool _isDownloading = false;
  bool _imageDownloaded = false;
  String? _localFilePath;

  static var imageFileCached = <String,String?>{};
  @override
  void initState() {
    super.initState();
    _checkImageDownloaded();
  }

  _checkImageDownloaded() async {
    _localFilePath = imageFileCached[widget.messageId] ??await MessageUtils.getLocalFilePath(widget.messageId);
    if (_localFilePath != null&&mounted) {
      File imageFile = File(_localFilePath!);
      if (imageFile.existsSync()) {
        imageFileCached[widget.messageId]=_localFilePath;
        setState(() => _imageDownloaded = true);
      } else {
        setState(() => _imageDownloaded = false);
      }
    }
  }

  _downloadAndDisplayImage() async {
    setState(() {
      _isDownloading = true;
    });
    imageFileCached.remove(widget.messageId);
    bool success = await MessageUtils.downloadAndSaveFile(
      context,
      widget.ref,
      widget.chatId,
      widget.messageId,
        MessageUtils.getFileExtension(MessageEnum.image),
    );

    if (success) {
      _checkImageDownloaded();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to download image')),
      );
    }

    setState(() {
      _isDownloading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const double imagePreviewHeight = 300.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            if (_imageDownloaded) {
              _displayFullImageDialog(context);
            }
          },
          child: _imageDownloaded
              ? _buildDownloadedImage(imagePreviewHeight)
              : _buildThumbnail(imagePreviewHeight),
        ),
        if (widget.caption?.isNotEmpty??false)
          Padding(
            padding: const EdgeInsets.all(4.0),
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

  Widget _buildDownloadedImage(double maxHeight) {
    return Center(
      child: Image.file(
        File(_localFilePath!),
        fit: BoxFit.cover,
        height: maxHeight,
        width: double.infinity, // Fill the width of the container
      ),
    );
  }

  Widget _buildThumbnail(double maxHeight) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ///place holder loader show before image is load
        const Center(
          child: CircularProgressIndicator(),
        ),
        widget.jpegThumbnail.isNotEmpty
            ? Image.memory(
                widget.jpegThumbnail,
                fit: BoxFit.cover,
                height: maxHeight,
                width: double.infinity,
              )
            : Image.asset(
                "assets/blurred.jpg",
                fit: BoxFit.cover,
                height: maxHeight,
                width: double.infinity,
              ),
        if (_isDownloading)
          const CircularProgressIndicator()
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.file_download, color: Colors.white),
              onPressed: _downloadAndDisplayImage,
            ),
          ),
      ],
    );
  }

  void _displayFullImageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            elevation: 0,
          ),
          body: Center(
            child: PhotoView(
              imageProvider: FileImage(File(_localFilePath!)),
              backgroundDecoration:
                  const BoxDecoration(color: Colors.transparent),
              minScale: PhotoViewComputedScale.contained * 1.0,
              maxScale: PhotoViewComputedScale.covered * 2.0,
            ),
          ),
        );
      },
    );
  }
}
