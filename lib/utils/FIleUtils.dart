import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class FileUtils {

  static Future<File> assetToFile(String assetPath) async {
    // Load the asset as bytes
    final ByteData data = await rootBundle.load(assetPath);

    // Get the temporary directory to store the file
    final Directory tempDir = await getTemporaryDirectory();
    String tempPath = tempDir.path;

    // Create a temporary file with a unique name
    File tempFile = File('$tempPath/${assetPath.split('/').last}');

    // Write the bytes to the file and return it
    return tempFile.writeAsBytes(data.buffer.asUint8List());
  }
}