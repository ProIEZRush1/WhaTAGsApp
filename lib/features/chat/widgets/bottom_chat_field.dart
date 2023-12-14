import 'dart:async';
import 'dart:io';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/audio_recording_message_service/audio_recorder_io.dart';
import 'package:com.jee.tag.whatagsapp/utils/EncryptionUtils.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:com.jee.tag.whatagsapp/common/utils/colors.dart';
import 'package:com.jee.tag.whatagsapp/common/enums/message_enum.dart';
import 'package:com.jee.tag.whatagsapp/common/providers/message_reply_provider.dart';
import 'package:com.jee.tag.whatagsapp/common/utils/utils.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/controller/chat_controller.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/message_reply_preview.dart';
import 'package:record/record.dart';
import 'package:whatsapp_camera/camera/camera_whatsapp.dart';
import 'package:whatsapp_camera/modle/file_media_model.dart';

class BottomChatField extends ConsumerStatefulWidget {
  final String recieverUserId;
  final bool isGroupChat;
  final Function(bool val) setShareVisibility;

  const BottomChatField({
    Key? key,
    required this.recieverUserId,
    required this.setShareVisibility,
    required this.isGroupChat,
  }) : super(key: key);

  @override
  ConsumerState<BottomChatField> createState() => _BottomChatFieldState();
}

class _BottomChatFieldState extends ConsumerState<BottomChatField> with AudioRecorderMixin {
  bool get isShowSendButton => _messageController.text.isNotEmpty;
  final TextEditingController _messageController = TextEditingController();
  // FlutterSoundRecorder? _soundRecorder;
  bool isRecorderInit = false;
  bool isShowEmojiContainer = false;
  bool isRecording = false;
  FocusNode focusNode = FocusNode();
  int _recordDuration = 0;
  Timer? _timer;
  late final AudioRecorder _audioRecorder;

  StreamSubscription<RecordState>? _recordSub;
  RecordState _recordState = RecordState.stop;
  StreamSubscription<Amplitude>? _amplitudeSub;
  Amplitude? _amplitude;

  @override
  void initState() {
    super.initState();
    // _soundRecorder = FlutterSoundRecorder();
    openAudio();
    _audioRecorder = AudioRecorder();

    _recordSub = _audioRecorder.onStateChanged().listen((recordState) {
      _updateRecordState(recordState);
    });

    _amplitudeSub = _audioRecorder
        .onAmplitudeChanged(const Duration(milliseconds: 300))
        .listen((amp) {
      setState(() => _amplitude = amp);
    });
  }


  void _updateRecordState(RecordState recordState) {
    setState(() => _recordState = recordState);

    switch (recordState) {
      case RecordState.pause:
        _timer?.cancel();
        break;
      case RecordState.record:
        _startTimer();
        break;
      case RecordState.stop:
        _timer?.cancel();
        _recordDuration = 0;
        break;
    }
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() => _recordDuration++);
    });
  }

  Future<void> _start() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        const encoder = AudioEncoder.aacLc;

        // We don't do anything with this but printing
        final isSupported = await _audioRecorder.isEncoderSupported(
          encoder,
        );

        if (!isSupported) {
          debugPrint('${encoder.name} supported: $isSupported');
        }

        final devs = await _audioRecorder.listInputDevices();
        debugPrint(devs.toString());

        const config = RecordConfig(encoder: encoder);

        // Record to file
        await recordFile(_audioRecorder, config);

        // Record to stream
        // await recordStream(_audioRecorder, config);

        _recordDuration = 0;

        _startTimer();
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<void> _stop() async {
    final path = await _audioRecorder.stop();

    if (path != null) {
      // widget.onStop(path);
      var file = File(path)..createSync(recursive: true);
      sendFileMessage(file, MessageEnum.voice);
      downloadWebData(path);
    }
  }

  void openAudio() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Mic permission not allowed!');
    }
    // await _soundRecorder!.openRecorder();
    isRecorderInit = true;
  }

  void sendCurrentLocation() async {
    var box = await Hive.openBox('config');
    String deviceId = box.get('lastDeviceId') ?? "";
    final key = box.get('lastEncryptionKey') ?? "";
    ref.read(chatControllerProvider).sendCurrentLocationMessage(
        context, ref, deviceId, widget.recieverUserId, key);
  }

  void sendTextMessage() async {
    var box = await Hive.openBox('config');

    String deviceId = box.get('lastDeviceId') ?? "";
    final key = box.get('lastEncryptionKey') ?? "";

    if (isShowSendButton) {
      final encryptedText =
          await EncryptionUtils.encrypt(_messageController.text, key);
      ref.read(chatControllerProvider).sendTextMessage(
          context, ref, deviceId, widget.recieverUserId, encryptedText, key);
      setState(() {
        _messageController.text = '';
      });
    } else {
      // var tempDir = await getTemporaryDirectory();
      // var path = '${tempDir.path}/flutter_sound.aac';
      // var file = File(path)..createSync();
      if (!isRecorderInit) {
        debugPrint('Recording not Init');
        return;
      }
      _start();
      // if (isRecording) {
      //   _stop();
      // }else{
      //   _start();
      // }

      // if (isRecording) {
      //   // await _soundRecorder!.stopRecorder();
      //   // sendFileMessage(file, MessageEnum.voice);
      // } else {
      //   // await _soundRecorder!.startRecorder(
      //   //   toFile: file.path,
      //   // );
      // }

      setState(() {
        isRecording = !isRecording;
      });
    }
  }

  void sendFileMessage(File file, MessageEnum messageEnum,
      {FileMediaModel? model}) async {
    var box = await Hive.openBox('config');
    String deviceId = box.get('lastDeviceId') ?? "";
    final key = box.get('lastEncryptionKey') ?? "";
    // debugPrint('deviceId $deviceId');
    ref.read(chatControllerProvider).sendMediaMessage(context, ref, deviceId,
        widget.recieverUserId, '', key, messageEnum, file,model:model);
  }

  // void selectImage() async {
  //   File? image = await pickImageFromGallery(context);
  //   if (image != null) {
  //     sendFileMessage(image, MessageEnum.image);
  //   }
  // }
  void selectImage() async {
    List<FileMediaModel>? res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WhatsappCamera(multiple: false),
      ),
    );
    if(res?.isNotEmpty??false){
      var file=res!.first;
      sendFileMessage(file.file,file.isImage?MessageEnum.image: MessageEnum.video,model: file);
    }
  }

  void selectVideo() async {
    File? video = await pickVideoFromGallery(context);
    if (video != null) {
      sendFileMessage(video, MessageEnum.video);
    }
  }

  void selectDocument() async {
    File? file = await pickFile(context);
    if (file != null) {
      sendFileMessage(file, MessageEnum.document);
    }
  }

  void selectGIF() async {
    final gif = await pickGIF(context);
    if (gif != null) {}
  }

  void hideEmojiContainer() {
    setState(() {
      isShowEmojiContainer = false;
    });
  }

  void showEmojiContainer() {
    setState(() {
      isShowEmojiContainer = true;
    });
  }

  void showKeyboard() => focusNode.requestFocus();

  void hideKeyboard() => focusNode.unfocus();

  void toggleEmojiKeyboardContainer() {
    if (isShowEmojiContainer) {
      showKeyboard();
      hideEmojiContainer();
    } else {
      hideKeyboard();
      showEmojiContainer();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _messageController.dispose();
    // _soundRecorder!.closeRecorder();
    isRecorderInit = false;
    _timer?.cancel();
    _recordSub?.cancel();
    _amplitudeSub?.cancel();
    _audioRecorder.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messageReply = ref.watch(messageReplyProvider);
    final isShowMessageReply = messageReply != null;
    return Column(
      children: [
        isShowMessageReply ? const MessageReplyPreview() : const SizedBox(),
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  bottom: 8,
                  right: 2,
                  left: 2,
                ),
                child: TextFormField(
                  focusNode: focusNode,
                  controller: _messageController,
                  onTap: () => widget.setShareVisibility(false),
                  onChanged: (val) {
                    setState(() {});
                    // if (val.isNotEmpty) {
                    //   setState(() {
                    //     isShowSendButton = true;
                    //   });
                    // } else {
                    //   setState(() {
                    //     isShowSendButton = false;
                    //   });
                    // }
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: mobileChatBoxColor,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SizedBox(
                        width: 50,
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: toggleEmojiKeyboardContainer,
                              icon: Icon(
                                isShowEmojiContainer
                                    ? Icons.keyboard_alt_outlined
                                    : Icons.emoji_emotions,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    suffixIcon: SizedBox(
                      width: 100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: selectImage,
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.grey,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              hideKeyboard();
                              widget.setShareVisibility(true);
                            },
                            // onPressed: selectGIF,
                            icon: const Icon(
                              Icons.attach_file,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    hintText: 'Type a message!',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: const BorderSide(
                        width: 0,
                        style: BorderStyle.none,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                bottom: 8,
                right: 2,
                left: 2,
              ),
              child: CircleAvatar(
                backgroundColor: const Color(0xFF128C7E),
                radius: 25,
                child: GestureDetector(
                  onTap: sendTextMessage,
                  child: Icon(
                    isShowSendButton
                        ? Icons.send
                        : isRecording
                            ? Icons.close
                            : Icons.mic,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        isShowEmojiContainer
            ? SizedBox(
                height: 310,
                child: EmojiPicker(
                  onEmojiSelected: ((category, emoji) {
                    setState(() {
                      _messageController.text =
                          _messageController.text + emoji.emoji;
                    });

                    // if (!isShowSendButton) {
                    //   setState(() {
                    //     isShowSendButton = true;
                    //   });
                    // }
                  }),
                ),
              )
            : const SizedBox(),
      ],
    );
  }
}
