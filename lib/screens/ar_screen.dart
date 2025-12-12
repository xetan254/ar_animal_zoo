import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

// --- IMPORT AR FLUTTER PLUGIN ---
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
// ------------------------------------

import '../data/zoo_data.dart';

class ARScreen extends StatefulWidget {
  final Animal animal;
  const ARScreen({super.key, required this.animal});

  @override
  State<ARScreen> createState() => _ARScreenState();
}

class _ARScreenState extends State<ARScreen> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  List<ARNode> nodes = [];
  List<ARAnchor> anchors = [];
  final player = AudioPlayer();
  bool isLoading = false;

  @override
  void dispose() {
    arSessionManager?.dispose();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.animal.name)),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          if (isLoading)
            const Center(
              child: Card(
                color: Colors.black54,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 10),
                      Text("Đang tải mô hình...",
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(8),
              color: Colors.black54,
              child: const Text(
                "Chạm vào các chấm trắng để hiển thị",
                style: TextStyle(color: Colors.white),
              ),
            ),
          )
        ],
      ),
    );
  }

  void onARViewCreated(
      ARSessionManager sessionManager,
      ARObjectManager objectManager,
      ARAnchorManager anchorManager,
      ARLocationManager locationManager) {
    arSessionManager = sessionManager;
    arObjectManager = objectManager;
    arAnchorManager = anchorManager;

    arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      customPlaneTexturePath: "Images/triangle.png",
      showWorldOrigin: false,
      handleTaps: true,
    );

    arObjectManager!.onInitialize();

    arSessionManager!.onPlaneOrPointTap = onPlaneOrPointTap;
  }

  // Copy file to App Documents Directory
  Future<String> _copyAssetToLocal(String assetPath) async {
    final filename = assetPath.split('/').last;
    final directory = await getApplicationDocumentsDirectory();
    final localPath = '${directory.path}/$filename';
    final file = File(localPath);

    // Always overwrite to ensure the file exists and is correct
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    await file.writeAsBytes(bytes, flush: true);

    // Return just the filename, not the full path
    return filename;
  }

  Future<void> onPlaneOrPointTap(List<ARHitTestResult> hitTestResults) async {
    if (hitTestResults.isEmpty || isLoading) return;

    var singleHitTestResult = hitTestResults.firstWhere(
        (hitTestResult) => hitTestResult.type == ARHitTestResultType.plane,
        orElse: () => hitTestResults.first);

    var newAnchor =
        ARPlaneAnchor(transformation: singleHitTestResult.worldTransform);
    bool? didAddAnchor = await arAnchorManager!.addAnchor(newAnchor);

    if (didAddAnchor == true) {
      anchors.add(newAnchor);
      setState(() {
        isLoading = true;
      });

      try {
        // 1. Copy file and get filename
        String fileName = await _copyAssetToLocal(widget.animal.modelPath);

        // 2. Create Node using fileSystemAppFolderGLB
        var newNode = ARNode(
          type:
              NodeType.fileSystemAppFolderGLB, // Use this type for local files
          uri: fileName, // Only pass the filename, NOT the full path
          scale:
              vector.Vector3(0.1, 0.1, 0.1), // Scale down (models can be huge)
          position: vector.Vector3(0.0, 0.0, 0.0),
          rotation: vector.Vector4(1.0, 0.0, 0.0, 0.0),
        );

        bool? didAddNodeToAnchor =
            await arObjectManager!.addNode(newNode, planeAnchor: newAnchor);
        if (didAddNodeToAnchor == true) {
          nodes.add(newNode);
          try {
            await player.play(AssetSource(
                widget.animal.soundPath.replaceFirst('assets/', '')));
          } catch (_) {}
        } else {
          arSessionManager!.onError("Failed to add node (Sceneform Error)");
        }
      } catch (e) {
        arSessionManager!.onError("Error: $e");
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}
