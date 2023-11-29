import 'package:cached_network_image/cached_network_image.dart';
import 'package:com.jee.tag.whatagsapp/common/widgets/loader.dart';
import 'package:flutter/material.dart';

class DialogUtils {
  static Dialog getProfileDialog(
      BuildContext context,
      String id,
      String? imageUrl,
      String name,
      GestureTapCallback onTapMessage,
      GestureTapCallback onTapCall,
      GestureTapCallback onTapVideoCall,
      GestureTapCallback onTapInfo) {
    Widget image = (imageUrl == null
        ? SizedBox(
            child: Center(
              // Center the entire content within the SizedBox
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                height: 350.0, // Set the height to 300.0
                width: 250.0, // Set the width to 250.0
                child: const Center(
                  // Center the icon within the container
                  child: Icon(
                    Icons.account_circle,
                    color: Colors.green,
                    size: 200.0,
                  ),
                ),
              ),
            ),
          )
        : Center(
            // Center the entire content within the SizedBox
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              height: 350.0, // Set the height to 300.0
              width: 350.0, // Set the width to 250.0
              child: Center(
                // Center the network image within the container
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  height: 350.0,
                  // Set the height to 300.0
                  width: 350.0,
                  // Set the width to 250.0
                  fit: BoxFit.cover,
                  progressIndicatorBuilder: (context, url, progress) =>
                      const Loader(),
                ),
                // child: Image(
                //   image: CachedNetworkImageProvider(imageUrl),
                //   height: 350.0, // Set the height to 300.0
                //   width: 350.0, // Set the width to 250.0
                //   fit: BoxFit.cover, // Adjust the fit property
                // ),
              ),
            ),
          ));
    return Dialog(
      shape: const RoundedRectangleBorder(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            child: Stack(
              children: <Widget>[
                image,
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.message),
                onPressed: onTapMessage,
                color: Colors.white,
              ),
              IconButton(
                icon: const Icon(Icons.call),
                onPressed: onTapCall,
                color: Colors.white,
              ),
              IconButton(
                icon: const Icon(Icons.videocam),
                onPressed: onTapVideoCall,
                color: Colors.white,
              ),
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: onTapInfo,
                color: Colors.white,
              ),
            ],
          )
        ],
      ),
    );
  }
}
