import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'dart:convert';

class FileUtils {
  static String getFileSizeString({required int bytes, int decimals = 0}) {
      const suffixes = ["b", "kb", "mb", "gb", "tb"];
      if (bytes == 0) return '0${suffixes[0]}';
      var i = (log(bytes) / log(1024)).floor();
      return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
    }
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

  static Future<File> downloadFile(String url, String filename) async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');

      return file.writeAsBytes(bytes);
    } else {
      throw Exception('Error downloading file');
    }
  }

  static Future<File> base64ToFile(String base64String, String fileName) async {
    // Remove data URI scheme prefix
    final split = base64String.split(',');
    final bytes = base64Decode(split.last);

    // Get the temporary directory
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/$fileName';

    // Write to the file
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    return file;
  }
}
