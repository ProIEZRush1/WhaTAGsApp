import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:com.jee.tag.whatagsapp/common/enums/message_enum.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/video_player_item.dart';
import 'package:flutter/rendering.dart';
import 'package:simple_vcard_parser/simple_vcard_parser.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Widget buildTextMessage(BuildContext context) {
    final RegExp linkRegExp = RegExp(
      r"((https?:\/\/)|www\.)[a-zA-Z0-9-._~:/?#[\]@!$&'()*+,;=%]+",
    );

    final Iterable<RegExpMatch> matches = linkRegExp.allMatches(message);
    final TextStyle defaultStyle = TextStyle(color: Colors.white, fontSize: 16);
    final TextStyle linkStyle = TextStyle(
      color: Colors.blue,
      fontSize: 16,
      decoration: TextDecoration.underline,
    );

    if (matches.isEmpty) {
      return Text(message, style: defaultStyle);
    } else {
      List<TextSpan> textSpans = [];
      int lastMatchEnd = 0;

      for (var match in matches) {
        textSpans.add(
          TextSpan(
              text: message.substring(lastMatchEnd, match.start),
              style: defaultStyle),
        );
        textSpans.add(
          TextSpan(
            text: message.substring(match.start, match.end),
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                String url = message.substring(match.start, match.end);
                if (!url.startsWith('http')) {
                  url = 'http://$url';
                }
                if (await canLaunch(url)) {
                  await launch(url);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not launch $url')),
                  );
                }
              },
          ),
        );
        lastMatchEnd = match.end;
      }

      if (lastMatchEnd < message.length) {
        textSpans.add(
          TextSpan(text: message.substring(lastMatchEnd), style: defaultStyle),
        );
      }

      return RichText(
        text: TextSpan(
          children: textSpans,
        ),
      );
    }
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
      videoUrl: media != null ? media! : "",
    );
  }

  Widget buildGIFMessage() {
    return Column(
      children: [
        CachedNetworkImage(
          imageUrl: media != null ? media! : "",
        ),
        Text(message),
      ],
    );
  }

  Widget buildImageMessage() {
    return Column(children: [
      CachedNetworkImage(
        imageUrl: media != null ? media! : "",
      )
    ]);
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
                title: Text(vCard.typedTelephone.first[0],
                    style: TextStyle(fontSize: 10)),
              ),
            // You can add more details like address, organization, etc.
          ],
        ),
        onTap: () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    //print(type);
    if (type == MessageEnum.text) {
      return buildTextMessage(context);
    } else if (type == MessageEnum.audio) {
      return buildAudioMessage();
    } else if (type == MessageEnum.video) {
      return buildVideoMessage();
    } else if (type == MessageEnum.gif) {
      return buildGIFMessage();
    } else if (type == MessageEnum.image) {
      return buildImageMessage();
    } else if (type == MessageEnum.vcard) {
      return buildVCardMessage();
    } else {
      return Column(
        children: [
          Text(message),
        ],
      );
    }
  }
}
