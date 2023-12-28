import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';

abstract class AudioController {
  ///Player id as map id
  static final Map<String?, AudioPlayer> _playerCached = {};

  static bool removePlayer(String? id) {
    var player = _playerCached.remove(id);
    player?.dispose();
    bool val = player != null;
    if (val) {
      debugPrint('removing PLayer $id');
    }
    return val;
  }

  static AudioPlayer? getPlayer(String? id) => _playerCached[id];

  static AudioPlayer addPlayer(String? id) {
    debugPrint('add PLayer $id');
    var player = AudioPlayer(
      playerId: id,
    );
    _playerCached[id] = player;
    return player;
  }
  //
  // static playNext(String? id,) {
  // int index= _playerCached.keys.toList().indexWhere((e) => e==id);
  // if(index!=-1){
  //   String? nextKey= _playerCached.keys.elementAtOrNull(index+1);
  //
  // }
  // }

  static bool play(String? id, File? file) {
    if (_playerCached.containsKey(id)) {
      try {
        _playerCached.values.forEach((element) async {
          if (element.state == PlayerState.playing) {
            await element.stop();
          }
        });
        _playerCached[id]!.play(BytesSource(file!.readAsBytesSync()));
        // _playerCached[id]!.play(DeviceFileSource(file!.path));
        // _playerCached[id]!.play(UrlSource('https://file-examples.com/storage/fe444bc7be658b44e9c7550/2017/11/file_example_MP3_5MG.mp3'));
        return true;
      } catch (e) {
        debugPrint('Error when playing $id Error:$e');
      }
    }
    return false;
  }
}
