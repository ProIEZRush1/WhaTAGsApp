import 'dart:async';
import 'dart:io';

// import 'package:camera_camera/camera_camera.dart';
import 'package:camera/camera.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_sliding_up_panel/flutter_sliding_up_panel.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_gallery/photo_gallery.dart';
import 'package:file_picker/file_picker.dart';
import 'package:whatsapp_camera/camera/view_image.dart';

class _WhatsAppCameraController extends ChangeNotifier {
  ///
  /// don't necessary to use this class
  /// this is the class to controller the actions
  ///
  _WhatsAppCameraController({this.multiple = true});

  /// permission to select multiple images
  ///
  /// multiple => default is true
  ///
  ///
  ///
  final bool multiple;
  final selectedImages = <File>[];
  var images = <Medium>[];

  Future<bool> handlerPermissions() async {
    final status = await Permission.storage.request();
    if (Platform.isIOS) {
      await Permission.photos.request();
      await Permission.mediaLibrary.request();
    }
    return status.isGranted;
  }

  bool imageIsSelected(String? fileName) {
    final index =
        selectedImages.indexWhere((e) => e.path.split('/').last == fileName);
    return index != -1;
  }

  _timer() {
    Timer.periodic(const Duration(seconds: 2), (t) async {
      Permission.camera.isGranted.then((value) {
        if (value) {
          getPhotosToGallery();
          t.cancel();
        }
      });
    });
  }

  Future<void> getPhotosToGallery() async {
    final permission = await handlerPermissions();
    if (permission) {
      final albums = await PhotoGallery.listAlbums(
        mediumType: MediumType.image,
      );
      final res = await Future.wait(albums.map((e) => e.listMedia()));
      final index = res.indexWhere((e) => e.album.name == 'All');
      if (index != -1) images.addAll(res[index].items);
      if (index == -1) {
        for (var e in res) {
          images.addAll(e.items);
        }
      }
      notifyListeners();
    }
  }

  Future<void> inicialize() async {
    _timer();
  }

  Future<void> openGallery() async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: multiple,
      type: FileType.image,
    );
    if (res != null) {
      for (var element in res.files) {
        if (element.path != null) selectedImages.add(File(element.path!));
      }
    }
  }

  void captureImage(File file) {
    selectedImages.add(file);
  }

  Future<void> selectImage(Medium image) async {
    if (multiple) {
      final index = selectedImages
          .indexWhere((e) => e.path.split('/').last == image.filename);
      if (index != -1) {
        selectedImages.removeAt(index);
      } else {
        final file = await image.getFile();
        selectedImages.add(file);
      }
    } else {
      selectedImages.clear();
      final file = await image.getFile();
      selectedImages.add(file);
    }
    notifyListeners();
  }
}

class WhatsappCamera extends StatefulWidget {
  /// permission to select multiple images
  ///
  /// multiple => default is true
  ///
  ///
  ///how use:
  ///```dart
  ///List<File>? res = await Navigator.push(
  /// context,
  /// MaterialPageRoute(
  ///   builder: (context) => const WhatsappCamera()),
  ///);
  ///
  ///```
  ///
  final bool multiple;

  /// how use:
  ///```dart
  ///List<File>? res = await Navigator.push(
  /// context,
  /// MaterialPageRoute(
  ///   builder: (context) => const WhatsappCamera()),
  ///);
  ///
  ///```
  ///
  const WhatsappCamera({super.key, this.multiple = true});

  @override
  State<WhatsappCamera> createState() => _WhatsappCameraState();
}

class _WhatsappCameraState extends State<WhatsappCamera>
    with WidgetsBindingObserver {
  late _WhatsAppCameraController controller;
  late CameraController camController;
  final painel = SlidingUpPanelController();
  bool _isLoading = true;

  @override
  void dispose() {
    controller.dispose();
    painel.dispose();
    stopTimer();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Navigator.pop(context);
    }
  }

  List<CameraDescription> _cameras = [];

  void initCamera() async {
    _cameras = await availableCameras();
    final front = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back);
    camController = CameraController(front, ResolutionPreset.medium);
    await camController.initialize();
    setState(() => _isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    initCamera();
    controller = _WhatsAppCameraController(multiple: widget.multiple);
    painel.addListener(() {
      if (painel.status.name == 'hidden') {
        controller.selectedImages.clear();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.inicialize();
    });
  }

  var _isRecording = false;

  Future<XFile?> _recordVideo() async {
    try {
      if (_isRecording) {
        final file = await camController.stopVideoRecording();
        stopTimer();
        setState(() => _isRecording = false);
        debugPrint('recording stop');
        return file;
        // final route = MaterialPageRoute(
        //   fullscreenDialog: true,
        //   builder: (_) => VideoPage(filePath: file.path),
        // );
        // Navigator.push(context, route);
      } else {
        await camController.prepareForVideoRecording();
        await camController.startVideoRecording();
        debugPrint('recording start');
        startTimer();
        setState(() => _isRecording = true);
      }
    } catch (e) {
      print('Error: $e');
    }
    return null;
  }

  Timer? timer;

  void stopTimer() {
    timer?.cancel();
  }

  void startTimer({bool rest=true}) {
    if(rest){
      videoDuration = const Duration(seconds: 1);
    }
    Timer.periodic(const Duration(seconds: 1), (timer) {
      this.timer = timer;
      videoDuration = Duration(seconds: videoDuration.inSeconds + 1);
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<XFile?> takePicture() async {
    final CameraController cameraController = camController;
    if (!cameraController.value.isInitialized) {
      debugPrint('Error: select a camera first.');
      return null;
    }

    if (cameraController.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      final XFile file = await cameraController.takePicture();
      return file;
    } on CameraException catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  setVideoMode(bool val) async {
    videoMode = val;
    print(videoMode);
    setState(() {});
  }

  toggleCamera() async {
    // if (camController.value.isRecordingVideo) {
    //   stopTimer();
    //  await camController.pauseVideoRecording();
    //  debugPrint('Video pause');
    // }
    final cam = _cameras.firstWhere((camera) =>
        camera.lensDirection != camController.description.lensDirection);
    await camController.setDescription(cam);
    // if (camController.value.isRecordingPaused) {
    //   await camController.resumeVideoRecording();
    //   startTimer(rest: false);
    //   debugPrint('Video resume');
    // }
  }

  Future<void> toggleFlashMode() async {
    var always = FlashMode.always;
    await camController.setFlashMode(
        camController.value.flashMode == always ? FlashMode.off : always);
    setState(() {});
  }

  bool videoMode = false;
  Duration videoDuration = Duration.zero;
  bool get isRecording{
    if(_isLoading){
      return false;
    }
    return camController.value.isRecordingVideo;
  }
  Future<void> setFlashMode(FlashMode mode) async {
    try {
      await camController.setFlashMode(mode);
    } on CameraException catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  Widget _cameraVideoTogglesRowWidget() {
    Widget button(String label, bool selected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected ? Colors.grey.withOpacity(.4) : Colors.transparent,
          // color: Colors.transparent,
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w400)),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (videoMode) const SizedBox(width: 50),
        InkWell(
          onTap: () => setVideoMode(true),
          child: button('Video', videoMode),
        ),
        const SizedBox(
          width: 5,
        ),
        InkWell(
          onTap: () => setVideoMode(false),
          child: button('Photo', !videoMode),
        ),
        if (!videoMode) const SizedBox(width: 50),
      ],
    );
  }

  Widget _cameraTogglesRowWidget() {
    if (_cameras.isEmpty) {
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        debugPrint('No camera found.');
      });
      return const Text('None');
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Row(
          // mainAxisSize: MainAxisSize.min,
          mainAxisAlignment:isRecording?MainAxisAlignment.center: MainAxisAlignment.spaceBetween,
          children: [
            if(!isRecording)
            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black45,
              ),
              child: IconButton(
                color: Colors.white,
                onPressed: () async {
                  controller.openGallery().then((value) {
                    if (controller.selectedImages.isNotEmpty) {
                      Navigator.pop(context, controller.selectedImages);
                    }
                  });
                },
                icon: const Icon(Icons.image),
              ),
            ),
            // const SizedBox(width: 10,),
            Container(
              // alignment: Alignment.center,
              padding: EdgeInsets.all(isRecording?10:5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white, width: 5),
                // shape: BoxShape.circle,
                color: Colors.black45,
              ),
              child: InkWell(
                onTap: () async {
                  XFile? file;
                  if (videoMode) {
                    file = await _recordVideo();
                  } else {
                    file = await takePicture();
                  }
                  if (file != null) {
                    controller.captureImage(File(file.path));
                    Navigator.pop(context, controller.selectedImages);
                  }
                },
                child: Icon(isRecording?Icons.square:Icons.circle, size:isRecording?20: 30,color:isRecording?Colors.red: Colors.white),
              ),
            ),
            // const SizedBox(width: 10,),
            if(!isRecording)
            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black45,
              ),
              child: IconButton(
                icon: const Icon(Icons.flip_camera_android),
                onPressed: toggleCamera,
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            )
          else
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: CameraPreview(
                camController,
                // child:
              ),
              // child: CameraCamera(
              //   enableZoom: false,
              //   resolutionPreset: ResolutionPreset.high,
              //   onFile: (file) {
              //     controller.captureImage(file);
              //     Navigator.pop(context, controller.selectedImages);
              //   },
              // ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  color: Colors.white,
                  onPressed: (() => Navigator.pop(context)),
                  icon: const Icon(Icons.close),
                ),
                if (videoMode)
                  Chip(
                      label: Text(
                          '${videoDuration.inMinutes.toString().padLeft(2, '0')}:${(videoDuration.inSeconds % 60).toString().padLeft(2, '0')}'),
                      backgroundColor:
                          videoDuration.inSeconds == 0 ? null : Colors.red),
                if (isRecording)
                  IconButton(
                    icon: Icon(camController.value.flashMode == FlashMode.always
                        ? Icons.flash_on
                        : Icons.flash_off),
                    onPressed: toggleFlashMode,
                  )else const SizedBox(width: 50,)
              ],
            ),
          ),
          Positioned(
            bottom: 15,
            left: 0.0,
            right: 0.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if(!isRecording)
                GestureDetector(
                  dragStartBehavior: DragStartBehavior.down,
                  onVerticalDragStart: (details) => painel.expand(),
                  child: SizedBox(
                    height: 120,
                    child: AnimatedBuilder(
                        animation: controller,
                        builder: (context, child) {
                          return Column(
                            children: [
                              if (controller.images.isNotEmpty)
                           const Icon(
                                Icons.remove,
                                color: Colors.white,
                              ),
                                // const RotatedBox(
                                //   quarterTurns: 1,
                                //   child: Icon(
                                //     Icons.arrow_back_ios,
                                //     color: Colors.white,
                                //   ),
                                // ),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: controller.images.length,
                                  physics: const BouncingScrollPhysics(),
                                  scrollDirection: Axis.horizontal,
                                  itemBuilder: (context, index) {
                                    return InkWell(
                                      onTap: () async {
                                        controller
                                            .selectImage(
                                                controller.images[index])
                                            .then((value) {
                                          Navigator.pop(
                                            context,
                                            controller.selectedImages,
                                          );
                                        });
                                      },
                                      child: Container(
                                        height: 100,
                                        width: 100,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 5),
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            fit: BoxFit.cover,
                                            isAntiAlias: true,
                                            filterQuality: FilterQuality.high,
                                            image: ThumbnailProvider(
                                              highQuality: true,
                                              mediumId:
                                                  controller.images[index].id,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        }),
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                _cameraTogglesRowWidget(),
                const SizedBox(
                  height: 15,
                ),
                if(!isRecording)
                _cameraVideoTogglesRowWidget()else const SizedBox(height: 32,)
              ],
            ),
          ),
          Center(
            child: SlidingUpPanelWidget(
              controlHeight: 0,
              panelController: painel,
              child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, child) {
                    return _ImagesPage(
                      controller: controller,
                      close: () {
                        painel.hide();
                      },
                      done: () {
                        if (controller.selectedImages.isNotEmpty) {
                          Navigator.pop(context, controller.selectedImages);
                        } else {
                          painel.hide();
                        }
                      },
                    );
                  }),
            ),
          )
        ],
      ),
    );
  }
}

class _ImagesPage extends StatefulWidget {
  final _WhatsAppCameraController controller;

  ///
  /// close action
  /// how use:
  /// ```dart
  /// close: () {
  ///   //pop painel
  /// }
  /// ```
  ///
  final void Function()? close;

  ///
  /// done action
  /// how use:
  /// ```dart
  /// done: () {
  ///   //send images
  /// }
  /// ```
  ///
  final void Function()? done;

  ///
  ///
  /// this is thi page of swipe to up
  /// and show the images of gallery
  /// don`t is necessary your implementation by the final programmer
  ///
  ///
  const _ImagesPage({
    required this.controller,
    required this.close,
    required this.done,
  });

  @override
  State<_ImagesPage> createState() => __ImagesPageState();
}

class __ImagesPageState extends State<_ImagesPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: MediaQuery.of(context).size.height - 40,
      child: Column(
        children: [
          Container(
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: widget.close?.call,
                  icon: const Icon(Icons.close, color: Colors.black),
                ),
                if (widget.controller.multiple)
                  Text(widget.controller.selectedImages.length.toString(),
                      style: const TextStyle(color: Colors.black)),
                IconButton(
                  onPressed: widget.done?.call,
                  icon: const Icon(Icons.check, color: Colors.black),
                )
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              itemCount: widget.controller.images.length,
              physics: const BouncingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisExtent: 140,
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
                childAspectRatio: MediaQuery.of(context).size.width /
                    (MediaQuery.of(context).size.height / 4),
              ),
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () => widget.controller
                      .selectImage(widget.controller.images[index]),
                  child: _ImageItem(
                    selected: widget.controller.imageIsSelected(
                      widget.controller.images[index].filename,
                    ),
                    image: widget.controller.images[index],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageItem extends StatelessWidget {
  ///
  /// medium image
  /// is formatter usage for package: photo_gallery
  /// this package list all images of device
  ///
  final Medium image;

  ///
  /// where selected is true, apply a check in the image
  ///
  final bool selected;

  ///
  ///this widget is usage how itemBuilder of painel: _ImagesPage
  ///
  const _ImageItem({required this.image, required this.selected});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Stack(
        children: [
          Hero(
            tag: image.id,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  image: ThumbnailProvider(
                    mediumId: image.id,
                    highQuality: true,
                    height: 150,
                    width: 150,
                    mediumType: MediumType.image,
                  ),
                ),
              ),
              // alignment: Alignment.center,
              // child: Text(image.filename ?? 'File'),
            ),
          ),
          if (selected)
            Container(
              color: Colors.grey.withOpacity(.3),
              child: Center(
                child: Stack(
                  children: [
                    const Icon(
                      Icons.done,
                      size: 52,
                      color: Colors.white,
                    ),
                    Icon(
                      Icons.done,
                      size: 50,
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              color: Colors.white,
              icon: const Icon(Icons.zoom_out_map_outlined),
              onPressed: () async {
                image.getFile().then((value) {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) {
                      return Hero(
                        tag: image.id,
                        child: ViewImage(image: value.path),
                      );
                    },
                  ));
                });
              },
            ),
          )
        ],
      ),
    );
  }
}
