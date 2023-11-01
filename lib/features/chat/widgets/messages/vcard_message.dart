import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:simple_vcard_parser/simple_vcard_parser.dart';

class VCardMessage extends StatefulWidget {
  final String vcard;
  final String? picture;

  const VCardMessage({super.key, required this.vcard, this.picture});

  @override
  _VCardMessageState createState() => _VCardMessageState();
}

class _VCardMessageState extends State<VCardMessage> {
  late VCard vCard;
  late ImageProvider<Object> imageProvider;

  @override
  void initState() {
    super.initState();
    vCard = VCard(widget.vcard);
    const defaultImage = AssetImage('assets/bg.png');

    if (widget.picture != null) {
      imageProvider = defaultImage;
    } else {
      imageProvider = defaultImage;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (vCard.typedTelephone.firstOrNull != null)
              ListTile(
                leading: const Icon(Icons.phone),
                title: Text(vCard.typedTelephone.first[0],
                    style: const TextStyle(fontSize: 10)),
              ),
            // You can add more details like address, organization, etc.
          ],
        ),
        onTap: () {},
      ),
    );
  }
}
