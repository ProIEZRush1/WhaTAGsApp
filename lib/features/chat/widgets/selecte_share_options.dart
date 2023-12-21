// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:com.jee.tag.whatagsapp/common/enums/message_enum.dart';
import 'package:com.jee.tag.whatagsapp/common/utils/utils.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/controller/chat_controller.dart';
import 'package:com.jee.tag.whatagsapp/features/select_contacts/screens/select_contacts_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:whatsapp_camera/modle/file_media_model.dart';
import 'package:whatsapp_camera/whatsapp_camera.dart';

class SelectShareOptionContainer extends StatefulWidget {
  const SelectShareOptionContainer({
    Key? key,
    required this.recieverUserId,
    required this.hideShareButton,
    required this.ref,
  }) : super(key: key);
  final String recieverUserId;
  final VoidCallback hideShareButton;
  final WidgetRef ref;

  @override
  State<SelectShareOptionContainer> createState() =>
      _SelectShareOptionContainerState();
}

class _SelectShareOptionContainerState
    extends State<SelectShareOptionContainer> {
  WidgetRef get ref => widget.ref;

  List<ShareItemModel> get items => [
        ShareItemModel(
          title: 'Document',
          icon: Icons.file_copy,
          color: Colors.deepPurple,
          onTap: selectDocument,
        ),
        ShareItemModel(
          title: 'Camera',
          icon: Icons.camera_alt,
          color: Colors.pink,
          onTap: selectImage,
        ),
        ShareItemModel(
          title: 'Gallery',
          // title: 'Video',
          icon: Icons.photo_rounded,
          // icon: Icons.video_camera_back_outlined,
          color: Colors.purple,
          onTap: selectVideoAndImage,
        ),
        ShareItemModel(
          title: 'Audio',
          icon: Icons.headphones,
          color: Colors.orange,
          onTap: null,
        ),
        ShareItemModel(
          title: 'Location',
          icon: Icons.location_on,
          color: Colors.green,
          onTap: sendCurrentLocation,
        ),
        ShareItemModel(
          title: 'Contact',
          icon: Icons.person,
          color: Colors.blue,
          onTap: sendContact,
        ),
      ];

  void selectDocument() async {
    File? file = await pickFile(context);

    if (file != null) {
      _sendFileMessage(file, MessageEnum.document);
    }
    widget.hideShareButton();
  }

  void selectImage() async {
    List<FileMediaModel>? res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WhatsappCamera(multiple: false),
      ),
    );
    if (res?.isNotEmpty ?? false) {
      var file = res!.first;
      _sendFileMessage(
          file.file, file.isImage ? MessageEnum.image : MessageEnum.video,
          model: file);
    }
    // File? image = await pickImageFromGallery(context);
    // if (image != null) {
    //   _sendFileMessage(image, MessageEnum.image);
    // }
    widget.hideShareButton();
  }

  void selectVideoAndImage() async {
    final imageExt = ['jpg', 'png'];
    final videoExt = ['mp4', 'avi', 'mov'];
    File? video =
        await pickFile(context, allowedExtensions: imageExt + videoExt);
    widget.hideShareButton();
    if (video != null) {
      _sendFileMessage(
          video,
          imageExt.contains(video.path.split('.').last)
              ? MessageEnum.image
              : MessageEnum.video);
    }
  }

  void sendCurrentLocation() async {
    var box = await Hive.openBox('config');
    String deviceId = box.get('lastDeviceId') ?? "";
    final key = box.get('lastEncryptionKey') ?? "";
    ref.read(chatControllerProvider).sendCurrentLocationMessage(
        context, ref, deviceId, widget.recieverUserId, key);
    widget.hideShareButton();
  }

  void sendContact() async {
    var result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SelectContactsScreen(shareContact: true),
        ));
    if (result is Contact) {
      var box = await Hive.openBox('config');
      String deviceId = box.get('lastDeviceId') ?? "";
      final key = box.get('lastEncryptionKey') ?? "";
      ref.read(chatControllerProvider).sendContactMessage(
          context, ref, deviceId, widget.recieverUserId, key,contact: result);
      widget.hideShareButton();
    }else{
      debugPrint('contact not selected $result');
    }
    return;
  }

  void _sendFileMessage(File file, MessageEnum messageEnum,
      {FileMediaModel? model}) async {
    var box = await Hive.openBox('config');
    String deviceId = box.get('lastDeviceId') ?? "";
    final key = box.get('lastEncryptionKey') ?? "";
    // debugPrint('deviceId $deviceId');
    ref.read(chatControllerProvider).sendMediaMessage(context, ref, deviceId,
        widget.recieverUserId, '', key, messageEnum, file,
        model: model);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      // height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      width: double.maxFinite,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 0,
        children: items
            .map(
              (e) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        if (e.onTap != null) {
                          e.onTap!();
                        } else {
                          widget.hideShareButton();
                          showSnackBar(
                              context: context,
                              content: '${e.title} not implement yet!!');
                        }
                      },
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: e.color ?? Colors.red,
                        child: Icon(
                          e.icon,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      e.title,
                      style: const TextStyle(color: Colors.grey),
                    )
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class ShareItemModel {
  String title;
  IconData icon;
  VoidCallback? onTap;
  Color? color;

  ShareItemModel(
      {required this.title, this.onTap, required this.icon, this.color});
}
