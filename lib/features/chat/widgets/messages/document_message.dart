import 'dart:io';

import 'package:com.jee.tag.whatagsapp/common/enums/message_enum.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/controller/download_upload_controller.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/download_button.dart';
import 'package:com.jee.tag.whatagsapp/utils/message_utils.dart';
import 'package:com.jee.tag.whatagsapp/utils/ColourUtils.dart';
import 'package:com.jee.tag.whatagsapp/utils/FileUtils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

class DocumentMessage extends ConsumerStatefulWidget {
  const DocumentMessage({
    super.key,
    required this.messageId,
    required this.chatId,
    this.sent,
    required this.fileName,
    required this.bytes,
  });

  final String chatId;
  final String messageId;
  final String fileName;
  final int bytes;
  final bool? sent;

  @override
  ConsumerState<DocumentMessage> createState() => _DocumentMessageState();
}

class _DocumentMessageState extends ConsumerState<DocumentMessage> {
  String get fileExtension => widget.fileName.split('.').last.toUpperCase();
  bool _isDownloading = false;
  bool _fileDownloaded = false;
  File? file;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _checkVideoDownloaded();
  }

  _checkVideoDownloaded() async {
    final localFilePath = await MessageUtils.getLocalFilePath(widget.messageId);

    if (localFilePath != null) {
      file = File(localFilePath);
      if (await file!.exists()) {
        _fileDownloaded = true;
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

  _downloadFile() async {
    _isDownloading = true;
    refresh();
    bool success = await UploadCtr.instance.downloadAndSaveFile(
        context, ref, widget.chatId, widget.messageId, MessageEnum.document
        // fileExtension,
        );

    if (success) {
      _checkVideoDownloaded();
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to download file')),
      );
    }

    _isDownloading = false;
    refresh();
  }

  openFile() async {
    try {
      if (file?.existsSync() ?? false) {
        print('opening file');
        var res = await MessageUtils.openFile(file!.path);
        print(res);
      } else {
        throw Exception();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File not found')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _fileDownloaded ? openFile : _downloadFile,
      child: Container(
        color: Colors.white.withOpacity(.1),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: getFileIcon(widget.fileName),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.fileName,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Row(
                    children: [
                      Text(
                        FileUtils.getFileSizeString(
                            bytes: widget.bytes, decimals: 1),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(
                          Icons.circle,
                          size: 3,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        fileExtension,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  )
                ],
              ),
            ),
            DownloadButton(
              key: ValueKey(widget.messageId),
              onSuccess: () {
                print('on Success called;');
                _checkVideoDownloaded();
              },
              messageId: widget.messageId,
              sent: widget.sent,
              // fileDownloaded: fileDownloaded,
              downloadAndSaveFile: () => UploadCtr.instance.downloadAndSaveFile(
                  context,
                  ref,
                  widget.chatId,
                  widget.messageId,
                  MessageEnum.document
                  // fileExtension,
                  ),
            ),
            // if (DownloadController.instance.downloadModel(widget.messageId)?.status==DownloadTaskStatus.enqueued||widget.sent==false||_isDownloading)
            //   Center(
            //     child: Row(
            //       children: [
            //         Text(DownloadController.instance.downloadModel(widget.messageId)?.progressForIndicator.toString()??'0000000'),
            //         CircularProgressIndicator(value: DownloadController.instance.downloadModel(widget.messageId)?.progressForIndicator),
            //       ],
            //     ),
            //   )
            // else
            //   _fileDownloaded
            //       ? const SizedBox()
            //       : GestureDetector(
            //           onTap: () {
            //             if (_fileDownloaded) {
            //               // _playVideo();
            //             }
            //           },
            //           child: SizedBox(
            //             child: Container(
            //               decoration: BoxDecoration(
            //                 color: Colors.black.withOpacity(0.5),
            //                 shape: BoxShape.circle,
            //               ),
            //               child: IconButton(
            //                 icon: const Icon(Icons.file_download,
            //                     color: Colors.white),
            //                 onPressed: _downloadFile,
            //               ),
            //             ),
            //           ),
            //         ),
            const SizedBox(
              width: 10,
            )
          ],
        ),
      ),
    );
  }

  Widget getFileIcon(String name) {
    Widget child = const SizedBox();
    child = Image.asset(
      'assets/icons8-file-52.png',
      color: Colors.red,
    );
    child = SvgPicture.string(getSVG(
      color: AppColors.getColorByExtension(fileExtension),
      fontSize: 14,
      title: fileExtension,
    ));
    return child;
  }

  String getSVG({int fontSize = 10, AppColors? color, String title = ''}) {
    return """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" width="90px" height="90px">
    <path fill="${color?.color ?? '#e62910'}" d="M40 45L8 45 8 3 30 3 40 13z" />
    <path fill="#78706f" d="M38.5 14L29 14 29 4.5z" />
     <text x="50%" y="70%" dominant-baseline="middle" text-anchor="middle" font-size='${fontSize - title.length}' fill='#FFFFFF'>$title</text>  
</svg>""";
  }
}
