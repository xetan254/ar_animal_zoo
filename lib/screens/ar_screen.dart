import 'dart:io';
// import 'package:flutter/foundation.dart';
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

  // Biến lưu tên file cache để tránh copy nhiều lần
  String? _cachedFileName;

  final player = AudioPlayer();
  bool isLoading = false;

  // --- BIẾN ĐIỀU KHIỂN ---
  double currentScale = 0.2;

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
          // 1. Màn hình Camera AR
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),

          // 2. Loading Indicator
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
                      Text("Đang xử lý...",
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),

          // 3. Hướng dẫn sử dụng
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(8),
              color: Colors.black54,
              child: const Text(
                "Chạm màn hình để đặt con vật.\nSử dụng nút bên dưới để đổi kích thước.",
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // 4. Control Panel - Điều khiển kích cỡ
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

  // --- KHỞI TẠO AR ---
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
      handlePans: true, // Cho phép di chuyển
      handleRotation: true, // Cho phép xoay
    );

    arObjectManager!.onInitialize();

    // Lắng nghe sự kiện chạm để đặt vật thể
    arSessionManager!.onPlaneOrPointTap = onPlaneOrPointTap;
  }

  // --- XỬ LÝ FILE (Copy 1 lần duy nhất) ---
  Future<String> _getOrPrepareModelFile() async {
    if (_cachedFileName != null) return _cachedFileName!;

    final assetPath = widget.animal.modelPath;
    final filename = assetPath.split('/').last;
    final directory = await getApplicationDocumentsDirectory();
    final localPath = '${directory.path}/$filename';
    final file = File(localPath);

    // Kiểm tra xem file đã tồn tại chưa, nếu chưa thì mới copy
    if (!await file.exists()) {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      await file.writeAsBytes(bytes, flush: true);
    }

    _cachedFileName = filename;
    return filename;
  }

  // --- XỬ LÝ CHẠM MÀN HÌNH ---
  Future<void> onPlaneOrPointTap(List<ARHitTestResult> hitTestResults) async {
    if (hitTestResults.isEmpty || isLoading) return;

    var singleHitTestResult = hitTestResults.firstWhere(
        (hitTestResult) => hitTestResult.type == ARHitTestResultType.plane,
        orElse: () => hitTestResults.first);

    // Xóa anchor cũ (nếu có) để đặt vị trí mới
    if (currentAnchor != null) {
      arAnchorManager!.removeAnchor(currentAnchor!);
      currentAnchor = null;
      currentNode = null;
    }

    // Tạo Anchor mới
    var newAnchor =
        ARPlaneAnchor(transformation: singleHitTestResult.worldTransform);
    bool? didAddAnchor = await arAnchorManager!.addAnchor(newAnchor);

    if (didAddAnchor == true) {
      currentAnchor = newAnchor;
      await _addNodeToAnchor(newAnchor, playSound: true);
    }
  }

  // --- HÀM THÊM NODE VÀO ANCHOR ---
  Future<void> _addNodeToAnchor(ARPlaneAnchor anchor,
      {bool playSound = false}) async {
    setState(() {
      isLoading = true;
    });

    try {
      String fileName = await _getOrPrepareModelFile();

      var newNode = ARNode(
        type: NodeType.fileSystemAppFolderGLB,
        uri: fileName,
        scale: vector.Vector3(currentScale, currentScale, currentScale),
        position: vector.Vector3(0.0, 0.0, 0.0),
        rotation: vector.Vector4(0.7071, 0.7071, 0, 0), // Góc mặc định
      );

      bool? didAddNodeToAnchor =
          await arObjectManager!.addNode(newNode, planeAnchor: anchor);

      if (didAddNodeToAnchor == true) {
        currentNode = newNode;
        if (playSound) {
          try {
            await player.play(AssetSource(
                widget.animal.soundPath.replaceFirst('assets/', '')));
          } catch (_) {}
        }
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

  // --- HÀM ĐIỀU KHIỂN SCALE ---
  void _incrementScale() {
    if (currentScale < 1.0) {
      setState(() {
        currentScale += 0.1;
        if (currentScale > 1.0) currentScale = 1.0;
      });
      _refreshNodeWithNewScale();
    }
  }

  void _decrementScale() {
    if (currentScale > 0.05) {
      setState(() {
        currentScale -= 0.1;
        if (currentScale < 0.05) currentScale = 0.05;
      });
      _refreshNodeWithNewScale();
    }
  }

  // --- LOGIC LÀM MỚI NODE (GIỮ VỊ TRÍ) ---
  Future<void> _refreshNodeWithNewScale() async {
    // Chỉ làm mới nếu con vật đang hiển thị
    if (currentAnchor != null && !isLoading) {
      try {
        // 1. Lưu lại vị trí (transformation) của anchor hiện tại
        var savedTransform = currentAnchor!.transformation;

        // 2. XÓA HOÀN TOÀN ANCHOR CŨ
        // Việc này đảm bảo node cũ biến mất 100%, không bị chồng hình
        await arAnchorManager!.removeAnchor(currentAnchor!);
        currentAnchor = null;
        currentNode = null;

        // 3. Tạo ngay một Anchor mới tại ĐÚNG VỊ TRÍ CŨ
        var newAnchor = ARPlaneAnchor(transformation: savedTransform);
        bool? didAdd = await arAnchorManager!.addAnchor(newAnchor);

        if (didAdd == true) {
          currentAnchor = newAnchor;
          // 4. Thêm lại model vào anchor mới với kích thước mới
          // Model sẽ reset về góc xoay mặc định do plugin không hỗ trợ lấy góc xoay cũ
          await _addNodeToAnchor(newAnchor, playSound: false);
        }
      } catch (e) {
        debugPrint("Error refreshing node: $e");
      }
    }
  }
}
