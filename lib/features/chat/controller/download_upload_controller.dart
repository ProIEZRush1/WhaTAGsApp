import 'dart:io';
import 'dart:isolate';

import 'package:background_downloader/background_downloader.dart';
import 'package:com.jee.tag.whatagsapp/utils/FIleUtils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../../../utils/message_utils.dart';

class DownloadCtr {}

final _fileDownloader = FileDownloader();

class UploadCtr extends ChangeNotifier {
  ///message id (default message will be show when we upload media)
  UploadCtr._();

  //
  static UploadCtr instance = UploadCtr._();
  static Map<String, AppUploadModel> uploads = {};
  static Map<String, AppUploadModel> downloads = {};

  inti() {
    // configure notification for all tasks
    _fileDownloader.configureNotification(
      running: const TaskNotification('Downloading', 'file: {filename}'),
      complete: const TaskNotification('Download finished', 'file: {filename}'),
      progressBar: true,
    );
// all downloads will now show a notification while downloading, and when complete.
// {filename} will be replaced with the task's filename.
  }

  Future<String?> upload(
      {required String path,
      required String url,
      required String id,
      Map<String, String>? data}) async {
    try {
      final name = path.split('/').last;

      /// define the multi-part upload task (subset of parameters shown)
      var f = await _saveFileToTempFolder(path);
      final task = UploadTask(
          taskId: id,
          url: url,
          filename: name,
          baseDirectory: BaseDirectory.temporary,
          fields: data,
          fileField: 'media',
          updates:
              Updates.statusAndProgress // request status and progress updates
          );
      // Start upload, and wait for result. Show progress and status changes
      // while uploading
      uploads[id] = AppUploadModel(status: TaskStatus.enqueued, progress: 0);
      final result = await _fileDownloader.upload(task, onProgress: (progress) {
        print('upload Progress: ${progress * 100}%');
        uploads[id]?.progress = progress;
        notifyListeners();
      }, onStatus: (status) {
        print('upload Status: ${status.isFinalState}');
        uploads[id]?.status = status;
        notifyListeners();
      });
      uploads.remove(id);
      f.delete();
      return result.responseBody;
    } catch (e) {
      debugPrint('Error $e');
    }
    uploads.remove(id);
    return null;
  }

  Future<String?> download(
      {required String path,
      required DownloadResponseModel data,}) async {
    var id = data.messageId;
    try {
      var dir = Directory(path);
      var appDir = await getApplicationDocumentsDirectory();
      var subDirPath =path.split('${appDir.path}/').last;
      print('sub dir == $subDirPath');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final task = DownloadTask(
          taskId: id,
          url: data.url,
          directory: subDirPath,
          filename: data.name,
          baseDirectory: BaseDirectory.applicationDocuments,
          allowPause: true,
          updates:
              Updates.statusAndProgress // request status and progress updates
          );
      // Start upload, and wait for result. Show progress and status changes
      // while uploading
      downloads[id] = AppUploadModel(status: TaskStatus.enqueued, progress: 0);
      final result =
          await _fileDownloader.download(task, onProgress: (progress) {
        print('upload Progress: ${progress * 100}%');
        if(progress==1){
          downloads[id]?.progress=null;
        }else {
          downloads[id]?.progress = progress;
        }
        notifyListeners();
      }, onStatus: (status) {
        print('upload Status: ${status.isFinalState}');
        downloads[id]?.status = status;
        // notifyListeners();
      });
      print(result.status);
      // downloads[id]?.progress = null;///to show continues loading
      // notifyListeners();
      await _decodeFile(data: data, dirPath:  dir.path);
      downloads.remove(id);
      notifyListeners();
      return result.responseBody;
    } catch (e) {
      debugPrint('Error $e');
    }
    downloads.remove(id);
    return null;
  }

  Future _decodeFile({
    required String dirPath,
    required DownloadResponseModel data,
  }) async {
    /// on successfully download
    var box = await Hive.openBox('config');
    var path = '$dirPath/${data.name}';
    print('Filve save on path $path');
    // var download = downloads[id];
    // if (download == null) {
    //   debugPrint('download not found ');
    //   return;
    // }
    // final result =await Isolate.run(()async=>FileUtils.decryptFile(path, iv: data.iv, key: data.cipherKey));
    // final result =
    //     await compute((param)async=>FileUtils.decryptFile(path, iv: data.iv, key: data.cipherKey),'Message');
    final result =
        await FileUtils.decryptFile(path, iv: data.iv, key: data.cipherKey);
    if (result) {
      box.put('localFilePath_${data.messageId}', path);
      debugPrint('decryptFile success');
    } else {
      debugPrint('decryptFile failed ${data.messageId}  ,  ${data.url}');
    }
    return null;
  }

  Future<File> _saveFileToTempFolder(String path) async {
    final name = path.split('/').last;

    /// define the multi-part upload task (subset of parameters shown)
    var tempDir = await getApplicationCacheDirectory();
    print(tempDir.path);
    var f = File('${tempDir.path}/$name')..createSync(recursive: true);
    await f.writeAsBytes(await File(path).readAsBytes());
    return f;
  }
}

class AppUploadModel {
  double? progress;
  TaskStatus status;

  double? get progressForIndicator {
    // if(status==TaskStatus.complete) return null;
    if(progress==null) return null;
    return (progress! * 100).toInt().toDouble() / 100;
  }

  AppUploadModel({required this.status, required this.progress});

// AppUploadModel copy(final double? progress, final TaskStatus? status) {
//   return AppUploadModel(
//       progress: progress ?? this.progress, status: this.status);
// }
}
