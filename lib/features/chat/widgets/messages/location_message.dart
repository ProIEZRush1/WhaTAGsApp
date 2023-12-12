import 'package:com.jee.tag.whatagsapp/utils/LocationUtils.dart';
import 'package:flutter/material.dart';

class LocationMessage extends StatelessWidget {
  const LocationMessage(
      {Key? key,
      required this.messageId,
      required this.lat,
      required this.long})
      : super(key: key);
  final String messageId;
  final double lat, long;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        var val = await LocationUtils.openMap(lat, long);
        if (val == false) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open map'),
            ),
          );
        }
      },
      child: SizedBox(
        width: 300,
        height: 160,
        child: Stack(
          children: [
            const Center(child: CircularProgressIndicator()),
            Image.network(
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress?.expectedTotalBytes ==
                    loadingProgress?.cumulativeBytesLoaded) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: child,
                  );
                }
                return Icon(
                  Icons.location_on,
                  color: Colors.white.withOpacity(.2),
                  size: 120,
                );
              },
              // width: 300,
              // height: 160,
              'https://maps.google.com/maps/api/staticmap?center=$lat,$long&zoom=15&size=300x160&markers=color:red%7Clabel:%7C$lat,$long&key=AIzaSyBAeEUvjFJvE8rwkDO9J86adS7yd9aM2Vs',
            ),
          ],
        ),
      ),
    );
  }
}
