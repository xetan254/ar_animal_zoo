import 'dart:io';
import 'dart:ui'; // Quan trọng cho hiệu ứng mờ (Glassmorphism)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:permission_handler/permission_handler.dart';

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

class _ARScreenState extends State<ARScreen> with WidgetsBindingObserver {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  ARNode? currentNode;
  ARPlaneAnchor? currentAnchor;

  String? _cachedFileName;
  final player = AudioPlayer();
  bool isLoading = false;

  // Mặc định scale 0.2, dùng cho Slider
  double currentScale = 0.2;

  bool _isPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    arSessionManager?.dispose();
    player.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isPermissionGranted) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    var status = await Permission.camera.status;
    if (status.isDenied) {
      status = await Permission.camera.request();
    }

    if (mounted) {
      setState(() {
        _isPermissionGranted = status.isGranted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPermissionGranted) {
      return _buildPermissionRequestUI();
    }

    return Scaffold(
      extendBodyBehindAppBar: true, // Cho phép nội dung tràn lên status bar
      appBar: null, // Tắt AppBar mặc định để tự custom
      body: Stack(
        children: [
          // 1. AR View (Nền)
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),

          // 2. Custom Header (Back button + Title)
          Positioned(
            top: 50, // Tránh tai thỏ
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Nút Back tròn
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white30),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 20),
                  ),
                ),

                // Tên con vật (Có đổ bóng)
                Text(
                  widget.animal.name.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                          color: Colors.black.withValues(alpha: 0.8),
                          blurRadius: 10)
                    ],
                  ),
                ),

                // Placeholder để cân đối layout (hoặc nút reset AR)
                const SizedBox(width: 40),
              ],
            ),
          ),

          // 3. Loading Indicator (Giữa màn hình)
          if (isLoading)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const CircularProgressIndicator(color: Colors.white),
              ),
            ),

          // 4. Hướng dẫn (Nằm dưới header)
          if (currentNode == null && !isLoading)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Chạm vào mặt phẳng (có chấm trắng) để đặt con vật",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ),

          // 5. Control Panel (Glassmorphism + Slider)
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Làm mờ
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    color:
                        Colors.white.withValues(alpha: 0.15), // Nền trong suốt
                    borderRadius: BorderRadius.circular(25),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Kích thước",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "${(currentScale * 10).toStringAsFixed(1)}x",
                            style: const TextStyle(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      // Slider điều chỉnh kích thước
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.greenAccent,
                          inactiveTrackColor: Colors.white24,
                          thumbColor: Colors.white,
                          overlayColor:
                              Colors.greenAccent.withValues(alpha: 0.2),
                          trackHeight: 4.0,
                        ),
                        child: Slider(
                          value: currentScale,
                          min: 0.05,
                          max: 1.0,
                          onChanged: (value) {
                            setState(() {
                              currentScale = value;
                            });
                          },
                          // Chỉ refresh model khi thả tay ra (để đỡ giật)
                          onChangeEnd: (value) {
                            _refreshNodeWithNewScale();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRequestUI() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
          title: Text(widget.animal.name), backgroundColor: Colors.transparent),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text("Cần quyền Camera để hiển thị AR",
                style: TextStyle(color: Colors.white)),
            const SizedBox(height: 20),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
              onPressed: () async {
                if (await Permission.camera.isPermanentlyDenied) {
                  openAppSettings();
                } else {
                  _checkPermission();
                }
              },
              child: const Text("Cấp quyền ngay",
                  style: TextStyle(color: Colors.black)),
            )
          ],
        ),
      ),
    );
  }

  // --- AR LOGIC (Giữ nguyên logic cốt lõi) ---

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

  Future<String> _getOrPrepareModelFile() async {
    if (_cachedFileName != null) return _cachedFileName!;

    final assetPath = widget.animal.modelPath;
    final filename = assetPath.split('/').last;
    final directory = await getApplicationDocumentsDirectory();
    final localPath = '${directory.path}/$filename';
    final file = File(localPath);

    if (!await file.exists()) {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      await file.writeAsBytes(bytes, flush: true);
    }

    _cachedFileName = filename;
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
      currentNode = null;
    }

    var newAnchor =
        ARPlaneAnchor(transformation: singleHitTestResult.worldTransform);
    bool? didAddAnchor = await arAnchorManager!.addAnchor(newAnchor);

    if (didAddAnchor == true) {
      currentAnchor = newAnchor;
      await _addNodeToAnchor(newAnchor, playSound: true);
    }
  }

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
        rotation: vector.Vector4(0.7071, 0.7071, 0, 0),
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

  Future<void> _refreshNodeWithNewScale() async {
    if (currentAnchor != null && !isLoading) {
      try {
        var savedTransform = currentAnchor!.transformation;
        await arAnchorManager!.removeAnchor(currentAnchor!);
        currentAnchor = null;
        currentNode = null;

        var newAnchor = ARPlaneAnchor(transformation: savedTransform);
        bool? didAdd = await arAnchorManager!.addAnchor(newAnchor);

        if (didAdd == true) {
          currentAnchor = newAnchor;
          await _addNodeToAnchor(newAnchor, playSound: false);
        }
      } catch (e) {
        debugPrint("Error refreshing node: $e");
      }
    }
  }
}
