import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/zoo_data.dart';
import 'animal_detail_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late CameraController controller;
  late FlutterVision vision;
  late List<Map<String, dynamic>> yoloResults;
  CameraImage? cameraImage;

  // Biến trạng thái
  bool _isPermissionGranted = false;
  bool isLoaded = false;
  bool isDetecting = false;
  bool isCameraInitialized = false;

  // Controller cho hiệu ứng quét (Scanning Animation)
  late AnimationController _scanAnimationController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Khởi tạo animation quét lên xuống
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true); // Chạy đi chạy lại

    // Kiểm tra quyền ngay khi vào
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanAnimationController.dispose();
    if (isCameraInitialized) {
      controller.dispose();
    }
    if (isLoaded) {
      vision.closeYoloModel();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_isPermissionGranted) {
        _checkPermission();
      }
    }
  }

  Future<void> _checkPermission() async {
    var status = await Permission.camera.status;
    if (status.isDenied) {
      status = await Permission.camera.request();
    }

    if (status.isGranted) {
      setState(() {
        _isPermissionGranted = true;
      });
      if (!isCameraInitialized) {
        init();
      }
    } else {
      setState(() {
        _isPermissionGranted = false;
      });
    }
  }

  init() async {
    try {
      final cameras = await availableCameras();
      vision = FlutterVision();
      controller = CameraController(cameras[0], ResolutionPreset.high);
      await controller.initialize();
      await loadYoloModel();

      if (mounted) {
        setState(() {
          isLoaded = true;
          isCameraInitialized = true;
          yoloResults = [];
        });
        startDetection();
      }
    } catch (e) {
      debugPrint("Error initializing: $e");
    }
  }

  Future<void> loadYoloModel() async {
    await vision.loadYoloModel(
      labels: 'assets/tflite/labels.txt',
      modelPath: 'assets/tflite/yolov8n.tflite',
      modelVersion: "yolov8",
      quantization: false,
      numThreads: 2,
      useGpu: true,
    );
  }

  Future<void> startDetection() async {
    if (!mounted ||
        !controller.value.isInitialized ||
        controller.value.isStreamingImages) {
      return;
    }

    setState(() {
      isDetecting = true;
    });

    try {
      await controller.startImageStream((image) async {
        if (isDetecting) {
          cameraImage = image;
          yoloOnFrame(image);
        }
      });
    } catch (e) {
      debugPrint("Error stream: $e");
    }
  }

  Future<void> yoloOnFrame(CameraImage cameraImage) async {
    final result = await vision.yoloOnFrame(
      bytesList: cameraImage.planes.map((plane) => plane.bytes).toList(),
      imageHeight: cameraImage.height,
      imageWidth: cameraImage.width,
      iouThreshold: 0.4,
      confThreshold: 0.4,
      classThreshold: 0.5,
    );

    if (result.isNotEmpty && mounted) {
      setState(() {
        yoloResults = result;
      });
    }
  }

  Animal? _findAnimalByLabel(String label) {
    try {
      final cleanLabel = label.toLowerCase().trim();
      return zooAnimals.firstWhere(
        (animal) => animal.id.toLowerCase() == cleanLabel,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Giao diện chưa có quyền
    if (!_isPermissionGranted) {
      return _buildPermissionRequestUI();
    }

    // 2. Giao diện đang load
    if (!isLoaded || !isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
            child: CircularProgressIndicator(
          color: Colors.greenAccent,
        )),
      );
    }

    // 3. Giao diện chính
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // A. Camera Preview
          CameraPreview(controller),

          // B. Hiệu ứng quét (Scanning Line)
          _buildScanningAnimation(size),

          // C. Các khung nhận diện
          ..._buildBoundingBoxes(size),

          // D. Hướng dẫn UI (Trên cùng)
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.center_focus_weak,
                        color: Colors.greenAccent, size: 20),
                    SizedBox(width: 10),
                    Text(
                      "Di chuyển camera để quét",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              "Cần quyền Camera để khám phá sở thú",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black),
              onPressed: () async {
                if (await Permission.camera.isPermanentlyDenied) {
                  openAppSettings();
                } else {
                  _checkPermission();
                }
              },
              child: const Text("Cấp quyền ngay"),
            )
          ],
        ),
      ),
    );
  }

  // Hiệu ứng thanh quét chạy dọc màn hình
  Widget _buildScanningAnimation(Size size) {
    return AnimatedBuilder(
      animation: _scanAnimationController,
      builder: (context, child) {
        return Positioned(
          top: _scanAnimationController.value * size.height,
          left: 0,
          right: 0,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                    color: Colors.greenAccent.withValues(alpha: 0.5),
                    blurRadius: 10)
              ],
              gradient: LinearGradient(
                colors: [
                  Colors.greenAccent.withValues(alpha: 0),
                  Colors.greenAccent,
                  Colors.greenAccent.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Vẽ các khung nhận diện đẹp hơn
  List<Widget> _buildBoundingBoxes(Size screen) {
    if (yoloResults.isEmpty || cameraImage == null) return [];

    double factorX = screen.width / (cameraImage!.height);
    double factorY = screen.height / (cameraImage!.width);

    return yoloResults.map((result) {
      double left = result["box"][0] * factorX;
      double top = result["box"][1] * factorY;
      double right = result["box"][2] * factorX;
      double bottom = result["box"][3] * factorY;

      String label = result['tag'];
      Animal? detectedAnimal = _findAnimalByLabel(label);

      // Màu sắc: Xanh lá nếu tìm thấy, Vàng cam nếu chưa rõ
      Color mainColor =
          detectedAnimal != null ? Colors.greenAccent : Colors.orangeAccent;

      return Positioned(
        left: left,
        top: top,
        width: right - left,
        height: bottom - top,
        child: GestureDetector(
          onTap: () {
            if (detectedAnimal != null) {
              isDetecting = false;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AnimalDetailScreen(animal: detectedAnimal),
                ),
              ).then((_) {
                isDetecting = true;
                if (!controller.value.isStreamingImages) {
                  startDetection();
                }
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text("Chưa có thông tin về '$label'"),
                duration: const Duration(seconds: 1),
                backgroundColor: Colors.orange,
              ));
            }
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Khung viền bo tròn, nền mờ
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: mainColor, width: 2.5),
                  color: mainColor.withValues(alpha: 0.15), // Nền mờ bên trong
                ),
              ),

              // 2. Thẻ tên (Pill Shape)
              Positioned(
                top: -40, // Đẩy lên trên khung
                left: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: mainColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        detectedAnimal != null
                            ? Icons.pets
                            : Icons.help_outline,
                        size: 16,
                        color: Colors.black87,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        detectedAnimal?.name ?? label.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
