import 'dart:io';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:flutter/material.dart';
import 'package:local_assets_server/local_assets_server.dart';

typedef CameraState = _CameraState;

class Camera extends StatefulWidget {
  const Camera({super.key});

  @override
  CameraState createState() => _CameraState();
}

class _CameraState extends State<Camera> {
  ArCoreController? arCoreController;
  int id = 1;

  late LocalAssetsServer server;
  bool isListening = false;
  String? address;
  int? port;

  @override
  void initState() {
    _initServer();
    super.initState();
  }

  void _initServer() async {
    server = LocalAssetsServer(
      address: InternetAddress.loopbackIPv4,
      assetsBasePath: 'assets',
      logger: const DebugLogger()
    );

    final address = await server.serve();
    this.address = address.address;
    port = server.boundPort;
    isListening = true;

    print('SERVER is $address $port');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Custom Object on plane detected'),
        ),
        body: ArCoreView(
          onArCoreViewCreated: _onArCoreViewCreated,
          enableTapRecognizer: true,
        ),
      ),
    );
  }

  void _onArCoreViewCreated(ArCoreController controller) {
    arCoreController = controller;
    arCoreController?.onNodeTap = (name) => onTapHandler(name);
    arCoreController?.onPlaneTap = _handleOnPlaneTap;
  }

  void _addModel(ArCoreHitTestResult plane) {
    final node = ArCoreReferenceNode(
      name: id.toString(),
      objectUrl: 'http://$address:$port/scene$id.gltf',
      // objectUrl: 'http://127.0.0.1:8000/scene{id}.gltf',
      position: plane.pose.translation,
      rotation: plane.pose.rotation,
    );

    arCoreController?.addArCoreNodeWithAnchor(node);
  }

  void onTapHandler(String name) {
    showDialog<void>(
      builder: (BuildContext context) => AlertDialog(
        content: Row(
          children: [
            const Text('Remove?'),
            IconButton(
              icon: const Icon(
                Icons.delete
              ),
              onPressed: () {
                arCoreController?.removeNode(nodeName: id.toString());
                id += 1;
                if (id > 2) {
                  id = 1;
                }
                Navigator.pop(context);
              },
            )
          ],
        ),
      ),
      context: context
    );
  }

  void _handleOnPlaneTap(List<ArCoreHitTestResult> hits) {
    final hit = hits.first;
    _addModel(hit);
  }

  @override
  void dispose() {
    arCoreController?.dispose();
    server.stop();
    super.dispose();
  }
}
