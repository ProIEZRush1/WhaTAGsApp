import 'dart:typed_data';

class ImageProperties {
  final double height;
  final double width;
  final String mimetype;
  final Uint8List jpegThumbnail;
  final String? caption;

  const ImageProperties({
    required this.height,
    required this.width,
    required this.mimetype,
    required this.jpegThumbnail,
    this.caption,
  });
}
