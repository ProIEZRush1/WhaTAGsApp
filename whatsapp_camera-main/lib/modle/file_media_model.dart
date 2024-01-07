import 'dart:io';

import 'package:photo_gallery/photo_gallery.dart';

class FileMediaModel{
 final File file;
 final bool isImage;
 final num? width,height,duration;
 final List<int>? thumbnail;
 FileMediaModel(this.file,{this.duration,this.width,this.height,this.thumbnail,this.isImage=true});
 static Future<FileMediaModel> fromMedium(Medium medium)async{
   return FileMediaModel(
    await medium.getFile(),
     width: medium.width,
     height: medium.height,
     duration: medium.duration,
     thumbnail: await medium.getThumbnail()
   );
 }
}