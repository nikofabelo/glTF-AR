import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gal/gal.dart';
import 'package:image/image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:vibration/vibration.dart';

typedef CameraState = _CameraState;

class Camera extends StatefulWidget {
  const Camera({super.key});

  @override
  CameraState createState() => CameraState();
}

class _CameraState extends State<Camera> {
  late ArCoreController arCoreController;
  final screenshotController = ScreenshotController();

  double whiteRectOpacity = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Screenshot(
          // controller: screenshotController,
        ArCoreView(
          enableTapRecognizer: true,
          onArCoreViewCreated: _onArCoreViewCreated
          // )
        ),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: whiteRectOpacity,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle
            )
          )
        ),
        Positioned(
          bottom: 90,
          left: (MediaQuery.of(context).size.width - 62) / 2,
          child: GestureDetector(
            onTap: _captureScreenshot,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 3.6
                ),
                shape: BoxShape.circle
              ),
              height: 62,
              width: 62,
              child: Center(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle
                  ),
                  height: 40,
                  width: 40
                )
              )
            )
          )
        )
      ]
    );
  }

  @override
  void dispose() {
    arCoreController.dispose();
    super.dispose();
  }

  void _onArCoreViewCreated(ArCoreController controller) {
    arCoreController = controller;
    // arCoreController.onNodeTap = (name) => _onNodeTap(name);
    // arCoreController.onPlaneTap = _onPlaneTap;
    _addModel();
  }

  Future<void> _captureScreenshot() async {
    if (!await Gal.hasAccess(toAlbum: true)) {
      if (!await Gal.requestAccess(toAlbum: true)) {
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate();
        }

        Fluttertoast.showToast(
          backgroundColor: Colors.red,
          gravity: ToastGravity.TOP,
          msg: GalExceptionType.accessDenied.message,
          toastLength: Toast.LENGTH_LONG
        );

        return;
      }
    }

    AudioPlayer().play(AssetSource('camera.mp3'));

    setState(() {
      whiteRectOpacity = 0.8;
    });
    await Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        whiteRectOpacity = 0;
      });
    });

    final capture = await screenshotController.capture();

    if (capture != null) {
      final image = decodePng(capture);

      bool isBlack = true;

      for (int x = 0; x < image!.width; x++) {
        for (int y = 0; y < image.height; y++) {
          final pixel = image.getPixel(x, y);

          if (pixel.r != 0 || pixel.g != 0 || pixel.b != 0) {
            isBlack = false;
          }
        }
      }

      if (isBlack)
      {
        Fluttertoast.showToast(
          backgroundColor: Colors.red,
          gravity: ToastGravity.TOP,
          msg: GalExceptionType.unexpected.message,
          toastLength: Toast.LENGTH_LONG
        );

        return;
      }

      final filename = DateTime.now().millisecondsSinceEpoch.toString();

      try {
        await Gal.putImageBytes(capture, album: 'AR world', name: filename);
      } on GalException catch (e) {
        Fluttertoast.showToast(
          backgroundColor: Colors.red,
          gravity: ToastGravity.TOP,
          msg: e.type.message,
          toastLength: Toast.LENGTH_LONG
        );

        return;
      }

      Fluttertoast.showToast(
        backgroundColor: Colors.green,
        gravity: ToastGravity.TOP,
        msg: 'Image saved, beautiful! 🥰',
        toastLength: Toast.LENGTH_SHORT
      );
    } else {
      Fluttertoast.showToast(
        backgroundColor: Colors.red,
        gravity: ToastGravity.TOP,
        msg: GalExceptionType.unexpected.message,
        toastLength: Toast.LENGTH_LONG
      );
    }
  }

  void _onNodeTap(String name)
  {
    print('onNodeTap!: {name}');
  }

  void _onPlaneTap(List<ArCoreHitTestResult> hits) {
    print('Plane tap detected!');
    // _addModel(hits.first);
  }

  Future<void> _addModel() async { // TODO
    final directory = await getExternalStorageDirectory();
    print('Directory is: ${directory?.path}');

    final node = ArCoreReferenceNode(
      name: 'Test',
      // object3DFileName: 'file:///sdcard/TEMP/assets/scene.gltf',
      objectUrl: 'https://github.com/nikofabelo/mnba/raw/main/ELCUADROPALMUSEO2.gltf',
      // position: plane.pose.translation,
      // rotation: plane.pose.rotation
      position: vector.Vector3(0, 0, 0),
      rotation: vector.Vector4(0, 0, 0, 0)
    );

    arCoreController.addArCoreNodeWithAnchor(node);
  }
}