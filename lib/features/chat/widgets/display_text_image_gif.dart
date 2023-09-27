import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:com.jee.tag.whatagsapp/common/enums/message_enum.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/video_player_item.dart';
import 'package:simple_vcard_parser/simple_vcard_parser.dart';

class DisplayTextImageGIF extends StatelessWidget {
  final String message;
  final String? media;
  final MessageEnum type;

  const DisplayTextImageGIF({
    Key? key,
    required this.message,
    this.media,
    required this.type,
  }) : super(key: key);

  Widget buildTextMessage() {
    return Text(
      message,
      style: const TextStyle(
        fontSize: 16,
      ),
    );
  }

  Widget buildAudioMessage() {
    bool isPlaying = false;
    final AudioPlayer audioPlayer = AudioPlayer();

    return StatefulBuilder(builder: (context, setState) {
      return IconButton(
        constraints: const BoxConstraints(
          minWidth: 100,
        ),
        onPressed: () async {
          if (isPlaying) {
            await audioPlayer.pause();
            setState(() {
              isPlaying = false;
            });
          } else {
            await audioPlayer.play(UrlSource(message));
            setState(() {
              isPlaying = true;
            });
          }
        },
        icon: Icon(
          isPlaying ? Icons.pause_circle : Icons.play_circle,
        ),
      );
    });
  }

  Widget buildVideoMessage() {
    return VideoPlayerItem(
      videoUrl: media!,
    );
  }

  Widget buildGIFMessage() {
    return Column(
      children: [
        CachedNetworkImage(
          imageUrl: media!,
        ),
        Text(message),
      ],
    );
  }

  Widget buildImageMessage() {
    return Column(
      children: [
        CachedNetworkImage(
          imageUrl: media != null ? media! : "HOLA",
        )
      ]
    );
  }

  Widget buildVCardMessage() {
    final VCard vCard = VCard(message);
    final defaultImage = const AssetImage('assets/bg.png');
    ImageProvider<Object>? imageProvider;

    if (media != null) {
      imageProvider = defaultImage;
    } else {
      imageProvider = defaultImage;
    }

    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: imageProvider,
          radius: 20,
        ),
        title: Text(
          vCard.formattedName ?? 'Contact',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (vCard.typedTelephone.firstOrNull != null)
              ListTile(
                leading: Icon(Icons.phone),
                title: Text(
                    vCard.typedTelephone.first[0],
                  style: TextStyle(
                    fontSize: 10
                  )
                ),
              ),
            // You can add more details like address, organization, etc.
          ],
        ),
        onTap: () {
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (type == MessageEnum.text) {
      return buildTextMessage();
    } else if (type == MessageEnum.audio) {
      return buildAudioMessage();
    } else if (type == MessageEnum.video) {
      return buildVideoMessage();
    } else if (type == MessageEnum.gif) {
      return buildGIFMessage();
    }
    else if (type == MessageEnum.image) {
      return buildImageMessage();
    }
    else if (type == MessageEnum.vcard) {
      return buildVCardMessage();
    }
    else {
      return Column(
        children: [
          Text(message),
        ],
      );
    }
  }
}