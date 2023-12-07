import 'package:flutter/material.dart';

class AppColors{
  final String color;
  AppColors._private(this.color);
  static AppColors red = AppColors._private('#e62910');
  static AppColors gry = AppColors._private('#758b98');
  static AppColors pink = AppColors._private('#f45454');
  static AppColors blue = AppColors._private('#63acf3');
  static AppColors yellow = AppColors._private('#fbcb3b');
  static AppColors green = AppColors._private('#77dca0');
  static AppColors getColorByExtension(String extension){
    switch (extension.toLowerCase()){
      case 'pdf':
        return pink;
      case 'docx':
        return blue;
      case 'pptx':
        return yellow;
      case 'xlsx':
        return green;
    }
    return gry;
  }
}

extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${alpha.toRadixString(16).padLeft(2, '0')}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}