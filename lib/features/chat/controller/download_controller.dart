// import 'dart:io';
// import 'dart:isolate';
// import 'dart:ui';
//
// import 'package:com.jee.tag.whatagsapp/features/chat/controller/chat_controller.dart';
// import 'package:com.jee.tag.whatagsapp/utils/FileUtils.dart';
// import 'package:com.jee.tag.whatagsapp/utils/message_utils.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_downloader/flutter_downloader.dart';
// import 'package:hive/hive.dart';
//
// enum DownloadAction {
//   retry,
//   remove,
//   open,
//   resume,
//   pause,
//   cancel,
// }
//
// class DownloadModel {
//   String? taskId;
//   int? progress;
//   DownloadTaskStatus? status;
//
//   DownloadModel({this.progress, this.status, this.taskId});
//
//   double? get progressForIndicator {
//     if (progress == null) return null;
//     return progress! / 100;
//   }
// }
//
// class DownloadController extends ChangeNotifier {
//   DownloadController._();
//
//   static DownloadController instance = DownloadController._();
//
//   ///ios setup remaining
//   ///https://pub.dev/packages/flutter_downloader#past-versions-and-sql-injection-vulnerabilities
//
//   ///Map<taskId,messageId>
//   final Map<String?, DownloadResponseModel> _ids = {};
//
//   ///Map<messageId,DownloadTask>
//   final Map<String?, DownloadModel?> _download = {};
//
//   DownloadModel? downloadModel(String messageId) => _download[messageId];
//
//   /*Below is the schema of the task table where flutter_downloader plugin stores information about download tasks
//  CREATE TABLE `task` (
//   `id`  INTEGER PRIMARY KEY AUTOINCREMENT,
//   `task_id` VARCHAR ( 256 ),
//   `url` TEXT,
//   `status`  INTEGER DEFAULT 0,
//   `progress`  INTEGER DEFAULT 0,
//   `file_name` TEXT,
//   `saved_dir` TEXT,
//   `resumable` TINYINT DEFAULT 0,
//   `headers` TEXT,
//   `show_notification` TINYINT DEFAULT 0,
//   `open_file_from_notification` TINYINT DEFAULT 0,
//   `time_created`  INTEGER DEFAULT 0
// );
//    */
//   Future init() async {
//     // var path = getApplicationDocumentsDirectory();
//     await FlutterDownloader.initialize(
//         debug: false,
//         // optional: set to false to disable printing logs to console (default: true)
//         ignoreSsl:
//             true // option: set to false to disable working with http links (default: false)
//         );
//
//     ReceivePort port = ReceivePort();
//     IsolateNameServer.registerPortWithName(
//         port.sendPort, 'downloader_send_port');
//     port.listen((dynamic data) async {
//       String id = data[0];
//       DownloadTaskStatus? status = DownloadTaskStatus.values[data[1]];
//       int progress = data[2];
//       print('data 😬 $data   ids=${_ids[id]?.messageId} $status');
//       if (_ids.containsKey(id)) {
//         // var task = await getTaskById(taskId: id);
//         final download = _ids[id];
//         _download[download?.messageId] =
//             DownloadModel(taskId: id, status: status, progress: progress);
//         print('update download ${download?.name} $progress');
//         notifyListeners();
//       }
//       if (status == DownloadTaskStatus.complete) {
//         /// on successfully download
//         var box = await Hive.openBox('config');
//         var task = await getTaskById(taskId: id);
//         var path = '${task?.savedDir}/${task?.filename}';
//         print('Filve save on path $path');
//         var download = _ids[id];
//         if (download == null) {
//           debugPrint('download not found ');
//           return;
//         }
//         final result =await FileUtils.decryptFile(path,
//             iv: download.iv, key: download.cipherKey);
//         if (result) {
//           box.put('localFilePath_${download.messageId}', path);
//           debugPrint('decryptFile success');
//         } else {
//           debugPrint(
//               'decryptFile failed ${download.messageId}  ,  ${download.url}');
//         }
//         // chatControllerProvider.re;
//         notifyListeners();
//       }
//     });
//
//     await FlutterDownloader.registerCallback(
//         downloadCallback); // callback is a top-level or static function
//   }
//
//   @pragma('vm:entry-point')
//   static void downloadCallback(String id, int status, int progress) {
//     final SendPort? send =
//         IsolateNameServer.lookupPortByName('downloader_send_port');
//     send?.send([id, status, progress]);
//   }
//
//   void loadAll() async {
//     final tasks = await FlutterDownloader.loadTasks();
//   }
//
//   Future<List<DownloadTask>?> loadByQuery(String query) async {
//     //SELECT * FROM task WHERE status=3
//     final tasks = await FlutterDownloader.loadTasksWithRawQuery(query: query);
//     return tasks;
//   }
//
//   Future<DownloadTask?> getTaskById({String? taskId}) async {
//     return (await loadByQuery('SELECT * FROM task WHERE task_id="$taskId"'))
//         ?.firstOrNull;
//   }
//
//   void performAction(DownloadAction action, String taskId) {
//     switch (action) {
//       case DownloadAction.retry:
//         FlutterDownloader.retry(taskId: taskId);
//         break;
//       case DownloadAction.remove:
//         FlutterDownloader.remove(taskId: taskId);
//         break;
//       case DownloadAction.open:
//         FlutterDownloader.open(taskId: taskId);
//         break;
//       case DownloadAction.resume:
//         FlutterDownloader.resume(taskId: taskId);
//         break;
//       case DownloadAction.pause:
//         FlutterDownloader.pause(taskId: taskId);
//         break;
//       case DownloadAction.cancel:
//         FlutterDownloader.cancel(taskId: taskId);
//         break;
//     }
//   }
//
//   void cancelAll(String id) {
//     FlutterDownloader.cancelAll();
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//     IsolateNameServer.removePortNameMapping('downloader_send_port');
//   }
//
//   Future<String?> download(DownloadResponseModel model, String path,
//       {String? fileName}) async {
//     var dir = Directory(path);
//     if (!dir.existsSync()) dir.createSync(recursive: true);
//     final taskId = await FlutterDownloader.enqueue(
//       url: model.url,
//       headers: {},
//       // optional: header send with url (auth token etc)
//       savedDir: path,
//       showNotification: true,
//       fileName: fileName,
//       // show download progress in status bar (for Android)
//       openFileFromNotification:
//           false, // click on notification to open downloaded file (for Android)
//     );
//     _ids[taskId] = model;
//     return taskId;
//   }
// }
