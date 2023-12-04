import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';

abstract class AudioController {
  static final Map<String?, AudioPlayer> _playerChase = {};

  static bool removePlayer(String? id) {
    bool val = _playerChase.remove(id) != null;
    if(val){
      debugPrint('removing PLayer $id');
    }
    return val;
  }

  static AudioPlayer? getPlayer(String? id) =>_playerChase[id];
  static AudioPlayer addPlayer(String? id) {
    debugPrint('add PLayer $id');
    var player = AudioPlayer(
      playerId: id,
    );
    _playerChase[id] = player;
    return player;
  }

  static bool play(String? id, File? file) {
    if (_playerChase.containsKey(id)) {
      try {
        _playerChase.values.forEach((element) async{
          if(element.state==PlayerState.playing) {
            await element.stop();
          }
        });
        _playerChase[id]!.play(BytesSource(file!.readAsBytesSync()));
        return true;
      } catch (e) {
        debugPrint('Error when playing $id Error:$e');
      }
    }
    return false;
  }
}
