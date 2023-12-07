import 'package:com.jee.tag.whatagsapp/utils/FIleUtils.dart';

class FileProperties{
  final int sizeInBytes;

  final String fileName;
  String get fileExtension =>fileName.split('.').last;
  String get fileSizeString=> FileUtils.getFileSizeString(bytes: sizeInBytes,decimals: 1);
  FileProperties({required this.sizeInBytes,required this.fileName});
}