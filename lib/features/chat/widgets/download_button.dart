import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/controller/download_controller.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/controller/download_upload_controller.dart';
import 'package:com.jee.tag.whatagsapp/utils/message_utils.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_downloader/flutter_downloader.dart';

class DownloadButton extends StatefulWidget {
  const DownloadButton(
      {Key? key,
      required this.onSuccess,
      required this.messageId,
      required this.sent,
      required this.downloadAndSaveFile})
      : super(key: key);
  final String messageId;
  final bool? sent;
  final Future<bool> Function() downloadAndSaveFile;
  final VoidCallback onSuccess;

  @override
  State<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> {
  bool _fileDownloaded = false, _isDownloading = false;

  _checkFileDownloaded({bool isInit = false}) async {
    final localFilePath = await MessageUtils.getLocalFilePath(widget.messageId);

    if (localFilePath != null) {
      var file = File(localFilePath);
      if (file.existsSync()) {
        _fileDownloaded = true;
        if (!isInit) widget.onSuccess();
        refresh();
        // _initializeVideoController(_localFilePath);
      } else {
        _fileDownloaded = false;
        refresh();
      }
    }
  }

  refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    _checkFileDownloaded(isInit: true);
    super.initState();
  }

/*
  DownloadModel? get download =>
      DownloadController.instance.downloadModel(widget.messageId);*/

  _downloadFile() async {
    // setState(() {
    _isDownloading = true;
    // });
    refresh();
    bool success = await widget.downloadAndSaveFile();

    if (success) {
      _checkFileDownloaded();
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to download file')),
      );
    }

    // setState(() {
    _isDownloading = false;
    // });
    refresh();
  }

  // bool get downloaded => ;

  AppUploadModel? get upload => UploadCtr.uploads[widget.messageId];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: UploadCtr.instance,
      builder: (context, child) {
        if (upload != null) {
          return Center(
            child:
                CircularProgressIndicator(value: upload?.progressForIndicator),
          );
        }
        // if () {
        //   return const SizedBox();
        // }
        if (upload?.status == TaskStatus.complete) {
          _checkFileDownloaded();
        }
        if (UploadCtr.downloadEnqueue(widget.messageId) == false) {
          // download complete.....
          print('// download complete.....');
          _checkFileDownloaded();
          UploadCtr.removeEnqueue(widget.messageId);
        }
        // if (download?.status == DownloadTaskStatus.complete) {
        //   _checkFileDownloaded();
        // }
        // if (download?.status == DownloadTaskStatus.enqueued ||
        //     download?.status == DownloadTaskStatus.running ||
        //     widget.sent == false ||
        if (_isDownloading || UploadCtr.downloadEnqueue(widget.messageId) == true) {
          return const Center(
            child: CircularProgressIndicator(
                // value: download?.progressForIndicator,
                ),
          );
        } else {
          return _fileDownloaded
              ? const SizedBox()
              : SizedBox(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.file_download,
                        color: Colors.white),
                    onPressed: _downloadFile,
                  ),
                ),
              );
        }
      },
    );
  }
}
