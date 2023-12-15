// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';

import 'package:com.jee.tag.whatagsapp/features/chat/controller/chat_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/src/consumer.dart';
import 'package:hive/hive.dart';
import 'package:simple_vcard_parser/simple_vcard_parser.dart';

class VCardMessage extends StatefulWidget {
  final String vcard;
  final String messageId;
  final String? picture;
  final WidgetRef ref;

  const VCardMessage(
      {super.key, required this.vcard, required this.messageId, this.picture, required this.ref});

  @override
  State<VCardMessage> createState() => _VCardMessageState();
}

class _VCardMessageState extends State<VCardMessage> {
  late VCard vCard;
  late ImageProvider<Object> imageProvider;
  static Map<String, String?> vcardProfileChased = {};

  @override
  void initState() {
    super.initState();
    vCard = VCard(widget.vcard);
    const defaultImage = AssetImage('assets/bg.png');
    final image = vCard.getImage();
    if (image != null) {
      imageProvider = MemoryImage(base64Decode(image));
    } else {
      imageProvider = defaultImage;
    }
    downloadProfileUrl();
  }

  String? profileUrl;

  void downloadProfileUrl() async {
    final id = vCard.getWaId() ?? '';
    profileUrl = vcardProfileChased[widget.messageId];
    if (profileUrl != null) {
      // print('profile chased $profileUrl');
      imageProvider = NetworkImage(profileUrl ?? '');
      setState(() {

      });
      return;
    }
    var box = await Hive.openBox('config');
    final deviceId = box.get('lastDeviceId') ?? "";
    final controller = widget.ref.read(chatControllerProvider);
    profileUrl = await controller.getProfileUrl(
      context,
      widget.ref,
      deviceId ?? "",
      id,
    );
    if (profileUrl != null) {
      vcardProfileChased[widget.messageId] = profileUrl;
      imageProvider = NetworkImage(profileUrl ?? '');
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: CircleAvatar(
                backgroundImage: imageProvider,
                radius: 20,
              ),
            ),
            // const SizedBox(width: 10,),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vCard.formattedName ?? 'Contact',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  if (vCard.typedTelephone.firstOrNull != null)
                    Row(
                      children: [
                        const Icon(Icons.phone),
                        Text(vCard.typedTelephone.first[0],
                            style: const TextStyle(fontSize: 10))
                      ],
                    )
                ],
              ),
            )
          ],
        ),
      ),
/*      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: imageProvider,
          radius: 20,
        ),
        title: Text(
          vCard.formattedName ?? 'Contact',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        // titleAlignment: ListTileTitleAlignment.top,
        subtitle: (vCard.typedTelephone.firstOrNull != null)?
          Row(
            children: [
              const Icon(Icons.phone),
              Text(vCard.typedTelephone.first[0],
                  style: const TextStyle(fontSize: 10))
            ],
          ):null,
        onTap: () {},
      ),*/
    );
  }
}

extension ImgExtendion on VCard {
  String? getImage() {
    var start = vCardString.indexOf('PHOTO;BASE64:');
    if (start == -1) {
      return null;
    } else {
      start += 13;
    }
    var end = vCardString.indexOf('\n', start);
    final photoBase64 = vCardString.substring(start, end);
    return photoBase64;
  }

  String? getWaId() {
    var start = vCardString.indexOf(';waid=');
    if (start == -1) {
      return null;
    } else {
      start += 6;
    }
    var end = vCardString.indexOf(':', start);
    final photoBase64 = vCardString.substring(start, end);
    return photoBase64;
  }
}
