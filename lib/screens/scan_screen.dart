import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui; // Import dart:ui để decode ảnh
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart'; // Thêm image_picker
import '../data/zoo_data.dart';
import 'animal_detail_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // --- Camera & AI Variables ---
  late CameraController controller;
  late FlutterVision vision;
  late List<Map<String, dynamic>> yoloResults;
  CameraImage? cameraImage;
  bool _isPermissionGranted = false;
  bool isLoaded = false;
  bool isDetecting = false;
  bool isCameraInitialized = false;

  // --- Animation Variables ---
  late AnimationController _scanAnimationController;

  // --- Image Picker Variables (Mới) ---
  File? _pickedImage; // File ảnh từ thư viện
  ui.Image? _decodedImage; // Ảnh đã decode để lấy kích thước thật
  bool _isImageMode = false; // Chế độ xem ảnh hay xem camera
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Animation quét quét
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanAnimationController.dispose();
    if (isCameraInitialized) controller.dispose();
    if (isLoaded) vision.closeYoloModel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isPermissionGranted) {
      _checkPermission();
    } else if (state == AppLifecycleState.paused && isCameraInitialized) {
      // Khi app ẩn đi, dừng camera nếu đang chạy
      if (!_isImageMode) {
        controller.stopImageStream();
        isDetecting = false;
      }
    } else if (state == AppLifecycleState.resumed && isCameraInitialized) {
      // Khi app hiện lại, bật lại camera nếu không ở chế độ xem ảnh
      if (!_isImageMode && !controller.value.isStreamingImages) {
        startDetection();
      }
    }
  }

  Future<void> _checkPermission() async {
    var status = await Permission.camera.status;
    if (status.isDenied) status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() => _isPermissionGranted = true);
      if (!isCameraInitialized) init();
    } else {
      setState(() => _isPermissionGranted = false);
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
        // Chỉ bắt đầu detect camera nếu không ở chế độ xem ảnh
        if (!_isImageMode) {
          startDetection();
        }
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
    setState(() => isDetecting = true);
    try {
      await controller.startImageStream((image) async {
        if (isDetecting && !_isImageMode) {
          cameraImage = image;
          yoloOnFrame(image);
        }
      });
    } catch (e) {
      debugPrint("Error stream: $e");
    }
  }

  Future<void> stopDetection() async {
    setState(() {
      isDetecting = false;
      yoloResults.clear();
    });
    if (controller.value.isStreamingImages) {
      await controller.stopImageStream();
    }
  }

  // --- Xử lý Detect trên Camera Frame ---
  Future<void> yoloOnFrame(CameraImage cameraImage) async {
    final result = await vision.yoloOnFrame(
      bytesList: cameraImage.planes.map((plane) => plane.bytes).toList(),
      imageHeight: cameraImage.height,
      imageWidth: cameraImage.width,
      iouThreshold: 0.4,
      confThreshold: 0.4,
      classThreshold: 0.5,
    );
    if (result.isNotEmpty && mounted) setState(() => yoloResults = result);
  }

  // --- Xử lý Detect trên Ảnh tĩnh (Mới) ---
  Future<void> yoloOnImage() async {
    if (_pickedImage == null) return;

    // Đọc bytes từ file ảnh
    final imageBytes = await _pickedImage!.readAsBytes();

    // Decode để lấy kích thước thật của ảnh (dùng để tính toán khung bao)
    final decodedImage = await decodeImageFromList(imageBytes);
    setState(() {
      _decodedImage = decodedImage;
    });

    final result = await vision.yoloOnImage(
      bytesList: imageBytes,
      imageHeight: decodedImage.height,
      imageWidth: decodedImage.width,
      iouThreshold: 0.4,
      confThreshold: 0.4,
      classThreshold: 0.5,
    );

    if (mounted) {
      setState(() {
        yoloResults = result;
      });
    }
  }

  // --- Hàm chọn ảnh từ thư viện ---
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        // 1. Dừng camera stream
        await stopDetection();

        setState(() {
          _pickedImage = File(image.path);
          _isImageMode = true; // Chuyển sang chế độ ảnh
          yoloResults = []; // Xóa kết quả cũ
        });

        // 2. Chạy detect trên ảnh mới
        await yoloOnImage();
      }
    } catch (e) {
      debugPrint("Lỗi chọn ảnh: $e");
    }
  }

  // --- Quay lại chế độ Camera ---
  void _backToCamera() {
    setState(() {
      _isImageMode = false;
      _pickedImage = null;
      _decodedImage = null;
      yoloResults = [];
    });
    startDetection();
  }

  Animal? _findAnimalByLabel(String label) {
    try {
      final cleanLabel = label.toLowerCase().trim();
      return zooAnimals
          .firstWhere((animal) => animal.id.toLowerCase() == cleanLabel);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPermissionGranted) return _buildPermissionRequestUI();
    if (!isLoaded || !isCameraInitialized) {
      return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator(color: Colors.green)));
    }

    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Lớp hiển thị: Camera hoặc Ảnh tĩnh
          if (_isImageMode && _pickedImage != null)
            Image.file(_pickedImage!, fit: BoxFit.contain)
          else
            CameraPreview(controller),

          // 2. Hiệu ứng quét (Chỉ hiện khi dùng Camera)
          if (!_isImageMode) _buildScanningAnimation(size),

          // 3. Khung bao (Bounding Boxes)
          ..._buildBoundingBoxes(size),

          // --- PHẦN THÊM MỚI: TIÊU ĐỀ TRÊN CÙNG ---
          Positioned(
            top: 50, // Đặt thấp hơn status bar
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3), // Nền mờ nhẹ
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Quét động vật trong sở thú",
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      const Shadow(
                        blurRadius: 4,
                        color: Colors.black,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // ----------------------------------------

          // 4. Các nút điều khiển
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 30,
      left: 20,
      right: 20,
      child: Column(
        children: [
          // Hướng dẫn
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white24)),
                child: Text(
                  _isImageMode
                      ? "Chế độ xem ảnh\n(Chạm vào để xem chi tiết)"
                      : "Di chuyển camera để quét\n(Chạm vào để xem chi tiết)",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Nút bấm
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween, // Đẩy nút ra 2 bên
            children: [
              // Nút tải ảnh lên (Bên trái)
              FloatingActionButton(
                heroTag: "btnGallery",
                backgroundColor: Colors.white.withValues(alpha: 0.8),
                onPressed: _pickImageFromGallery,
                child: const Icon(Icons.photo_library, color: Colors.black),
              ),

              // Nút quay lại camera (Bên phải - chỉ hiện khi đang xem ảnh)
              if (_isImageMode)
                FloatingActionButton(
                  heroTag: "btnCam",
                  backgroundColor: Colors.white,
                  onPressed: _backToCamera,
                  child: const Icon(Icons.videocam, color: Colors.black),
                )
              else
                // Widget rỗng để giữ cân bằng layout nếu cần, hoặc để trống
                const SizedBox(width: 56),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPermissionRequestUI() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            Text("Cần quyền truy cập Camera", style: GoogleFonts.roboto()),
            ElevatedButton(
              onPressed: _checkPermission,
              child: Text("Cấp quyền", style: GoogleFonts.roboto()),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildScanningAnimation(Size size) {
    return AnimatedBuilder(
      animation: _scanAnimationController,
      builder: (context, child) {
        return Positioned(
          top: _scanAnimationController.value * size.height,
          left: 0,
          right: 0,
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                    color: Colors.greenAccent.withValues(alpha: 0.6),
                    blurRadius: 15)
              ],
              gradient: const LinearGradient(colors: [
                Colors.transparent,
                Colors.greenAccent,
                Colors.transparent
              ]),
            ),
          ),
        );
      },
    );
  }

  // Xử lý tính toán vị trí khung bao
  List<Widget> _buildBoundingBoxes(Size screen) {
    if (yoloResults.isEmpty) return [];

    double factorX, factorY;

    if (_isImageMode && _decodedImage != null) {
      // Logic tính toán cho ẢNH TĨNH (BoxFit.contain)
      double imgW = _decodedImage!.width.toDouble();
      double imgH = _decodedImage!.height.toDouble();

      // Tính toán tỷ lệ scale của ảnh khi hiển thị trên màn hình
      double scale = (screen.width / imgW < screen.height / imgH)
          ? screen.width / imgW
          : screen.height / imgH;

      double displayedW = imgW * scale;
      double displayedH = imgH * scale;

      // Tính khoảng trống (offset) do BoxFit.contain tạo ra
      double offsetX = (screen.width - displayedW) / 2;
      double offsetY = (screen.height - displayedH) / 2;

      return yoloResults.map((result) {
        // Tọa độ gốc từ YOLO
        double x1 = result["box"][0];
        double y1 = result["box"][1];
        double x2 = result["box"][2];
        double y2 = result["box"][3];

        // Scale tọa độ
        double left = x1 * scale + offsetX;
        double top = y1 * scale + offsetY;
        double width = (x2 - x1) * scale;
        double height = (y2 - y1) * scale;

        return _buildBoxWidget(left, top, width, height, result);
      }).toList();
    } else if (!_isImageMode && cameraImage != null) {
      // Logic tính toán cho CAMERA
      factorX = screen.width / (cameraImage!.height);
      factorY = screen.height / (cameraImage!.width);

      return yoloResults.map((result) {
        double left = result["box"][0] * factorX;
        double top = result["box"][1] * factorY;
        double right = result["box"][2] * factorX;
        double bottom = result["box"][3] * factorY;

        return _buildBoxWidget(left, top, right - left, bottom - top, result);
      }).toList();
    }

    return [];
  }

  // Widget hiển thị từng ô vuông
  Widget _buildBoxWidget(double left, double top, double width, double height,
      Map<String, dynamic> result) {
    String label = result['tag'];
    Animal? detectedAnimal = _findAnimalByLabel(label);
    Color mainColor =
        detectedAnimal != null ? Colors.greenAccent : Colors.orangeAccent;

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        onTap: () {
          if (detectedAnimal != null) {
            // Dừng detect khi chuyển màn hình
            if (!_isImageMode) isDetecting = false;

            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        AnimalDetailScreen(animal: detectedAnimal))).then((_) {
              // Khi quay lại, bật lại detect
              if (!_isImageMode) {
                isDetecting = true;
                if (!controller.value.isStreamingImages) startDetection();
              }
            });
          }
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: mainColor, width: 2),
                color: mainColor.withValues(alpha: 0.2),
              ),
            ),
            Positioned(
              top: -30,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: mainColor, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(detectedAnimal != null ? Icons.pets : Icons.help,
                        size: 14, color: Colors.black),
                    const SizedBox(width: 4),
                    Text(
                        "${detectedAnimal?.name ?? label} ${(result['box'][4] * 100).toStringAsFixed(0)}%",
                        style: GoogleFonts.roboto(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
