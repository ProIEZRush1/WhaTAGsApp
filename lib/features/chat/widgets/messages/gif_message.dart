import 'package:flutter/material.dart';

class GifMessage extends StatelessWidget {
  final String gifUrl;

  const GifMessage({super.key, required this.gifUrl});

  @override
  Widget build(BuildContext context) {
    return Image.network(
        gifUrl); // Assuming you're fetching the GIF from a URL.
  }
}
