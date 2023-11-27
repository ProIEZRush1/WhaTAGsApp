import 'dart:typed_data';

class VideoProperties {
  final double height;
  final double width;
  final int seconds;
  final String mimetype;
  final Uint8List jpegThumbnail;
  final String? caption;

  const VideoProperties({
    required this.height,
    required this.width,
    required this.seconds,
    required this.mimetype,
    required this.jpegThumbnail,
    this.caption,
  });
}
