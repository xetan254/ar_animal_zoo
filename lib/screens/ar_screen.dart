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

  ARNode? currentNode;
  ARPlaneAnchor? currentAnchor;

  final player = AudioPlayer();
  bool isLoading = false;

  // --- BIẾN ĐIỀU KHIỂN ---
  double currentScale = 0.2;
  int modelVersion = 0;
  @override
  void dispose() {
    arSessionManager?.dispose();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.animal.name),
        backgroundColor: Colors.green,
      ),
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

          // Hướng dẫn
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(8),
              color: Colors.black54,
              child: const Text(
                "Chạm vào chấm trắng để đặt con vật.\nXoay bằng tay trên màn hình.",
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Control Panel - Chỉ có button +/- kích cỡ
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Hiển thị giá trị kích cỡ
                  Text(
                    'Kích cỡ: ${(currentScale * 10).toStringAsFixed(1)}x',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Nút +/-
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _decrementScale,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          minimumSize: const Size(60, 40),
                        ),
                        child: const Icon(Icons.remove,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _incrementScale,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          minimumSize: const Size(60, 40),
                        ),
                        child: const Icon(Icons.add,
                            color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
      handlePans: true,
      handleRotation: true,
    );

    arObjectManager!.onInitialize();
    arSessionManager!.onPlaneOrPointTap = onPlaneOrPointTap;
  }

  Future<String> _copyAssetToLocal(String assetPath) async {
    final filename = assetPath.split('/').last;
    final directory = await getApplicationDocumentsDirectory();
    final localPath = '${directory.path}/$filename';
    final file = File(localPath);

    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    await file.writeAsBytes(bytes, flush: true);

    return filename;
  }

  Future<void> onPlaneOrPointTap(List<ARHitTestResult> hitTestResults) async {
    if (hitTestResults.isEmpty || isLoading) return;

    var singleHitTestResult = hitTestResults.firstWhere(
        (hitTestResult) => hitTestResult.type == ARHitTestResultType.plane,
        orElse: () => hitTestResults.first);

    if (currentAnchor != null) {
      arAnchorManager!.removeAnchor(currentAnchor!);
      currentAnchor = null;
    }
    if (currentNode != null) {
      arObjectManager!.removeNode(currentNode!);
      currentNode = null;
    }

    var newAnchor =
        ARPlaneAnchor(transformation: singleHitTestResult.worldTransform);
    bool? didAddAnchor = await arAnchorManager!.addAnchor(newAnchor);

    if (didAddAnchor == true) {
      currentAnchor = newAnchor;
      setState(() {
        isLoading = true;
      });

      try {
        String fileName = await _copyAssetToLocal(widget.animal.modelPath);

        var newNode = ARNode(
          type: NodeType.fileSystemAppFolderGLB,
          uri: fileName,
          scale: vector.Vector3(currentScale, currentScale, currentScale),
          position: vector.Vector3(0.0, 0.0, 0.0),
        );

        bool? didAddNodeToAnchor =
            await arObjectManager!.addNode(newNode, planeAnchor: newAnchor);
        if (didAddNodeToAnchor == true) {
          currentNode = newNode;
          try {
            await player.play(AssetSource(
                widget.animal.soundPath.replaceFirst('assets/', '')));
          } catch (_) {}
        } else {
          arSessionManager!.onError("Failed to add node");
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

  // --- HÀM ĐIỀU KHIỂN SCALE ---
  void _incrementScale() {
    setState(() {
      if (currentScale < 1.0) {
        currentScale += 0.1;
        if (currentScale > 1.0) currentScale = 1.0;
      }
    });
    _updateNodeScale();
  }

  void _decrementScale() {
    setState(() {
      if (currentScale > 0.05) {
        currentScale -= 0.1;
        if (currentScale < 0.05) currentScale = 0.05;
      }
    });
    _updateNodeScale();
  }

// --- HÀM CẬP NHẬT SCALE CỦA NODE ---
  Future<void> _updateNodeScale() async {
    if (currentNode != null && currentAnchor != null) {
      try {
        // Xoá node cũ trước
        await arObjectManager!.removeNode(currentNode!);
        currentNode = null;

        // Tạo lại node với scale mới
        await _recreateNodeWithNewScale();
      } catch (e) {
        print("Error updating node: $e");
      }
    }
  }

  // --- HÀM TẠO LẠI NODE VỚI SCALE MỚI ---
  Future<void> _recreateNodeWithNewScale() async {
    if (currentAnchor != null) {
      try {
        // Xoá tất cả file cũ trong cache
        final directory = await getApplicationDocumentsDirectory();
        final baseFilename = widget.animal.modelPath.split('/').last;
        final baseName = baseFilename.split('.').first;
        final extension = baseFilename.split('.').last;

        // Xoá tất cả phiên bản cũ
        final dir = Directory(directory.path);
        final files = dir.listSync();
        for (var file in files) {
          if (file is File && file.path.contains(baseName)) {
            try {
              await file.delete();
              print("Deleted old file: ${file.path}");
            } catch (_) {}
          }
        }

        // Tăng version để tạo tên file mới
        modelVersion++;
        String newFileName = '${baseName}_v${modelVersion}.$extension';

        // Copy file mới với tên unique
        final localPath = '${directory.path}/$newFileName';
        final newFile = File(localPath);

        final data = await rootBundle.load(widget.animal.modelPath);
        final bytes = data.buffer.asUint8List();
        await newFile.writeAsBytes(bytes, flush: true);

        print("Created new model file: $newFileName");

        // Tạo node mới với scale mới
        var newNode = ARNode(
          type: NodeType.fileSystemAppFolderGLB,
          uri: newFileName,
          scale: vector.Vector3(currentScale, currentScale, currentScale),
          position: vector.Vector3(0.0, 0.0, 0.0),
          rotation: vector.Vector4(0.7071, 0.7071, 0, 0),
        );

        // Thêm node mới vào scene
        bool? didAddNode = await arObjectManager!
            .addNode(newNode, planeAnchor: currentAnchor!);
        if (didAddNode == true) {
          currentNode = newNode;
          print(
              "Node recreated - Scale: ${(currentScale * 10).toStringAsFixed(1)}x, Version: $modelVersion");
        }
      } catch (e) {
        print("Error recreating node: $e");
      }
    }
  }
}
