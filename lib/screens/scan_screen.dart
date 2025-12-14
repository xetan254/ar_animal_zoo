import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_vision/flutter_vision.dart'; // Thư viện AI YOLO
import '../data/zoo_data.dart'; // Nơi chứa dữ liệu Animal và danh sách zooAnimals
import 'animal_detail_screen.dart'; // Trang chi tiết

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  late CameraController controller;
  late FlutterVision vision;
  late List<Map<String, dynamic>> yoloResults;
  CameraImage? cameraImage;
  bool isLoaded = false;
  bool isDetecting = false;
  bool isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  // Khởi tạo Camera và Model AI
  init() async {
    // 1. Khởi tạo Camera
    final cameras = await availableCameras();
    vision = FlutterVision();

    // Chọn camera sau (index 0), độ phân giải cao
    controller = CameraController(cameras[0], ResolutionPreset.high);
    await controller.initialize();

    // 2. Load Model YOLO
    await loadYoloModel();

    // 3. Cập nhật trạng thái UI
    if (mounted) {
      setState(() {
        isLoaded = true;
        isCameraInitialized = true;
        yoloResults = [];
      });

      // Tự động bắt đầu detect ngay khi vào màn hình
      startDetection();
    }
  }

  @override
  void dispose() {
    // Giải phóng tài nguyên khi thoát màn hình
    controller.dispose();
    vision.closeYoloModel();
    super.dispose();
  }

  // Load file model TFLite và Labels
  Future<void> loadYoloModel() async {
    await vision.loadYoloModel(
      labels: 'assets/tflite/labels.txt',
      modelPath:
          'assets/tflite/yolov8n.tflite', // Đảm bảo file này có trong assets
      modelVersion: "yolov8",
      quantization: false,
      numThreads: 2,
      useGpu: true, // Bật GPU để mượt hơn
    );
  }

  // Bắt đầu luồng nhận diện
  Future<void> startDetection() async {
    if (!mounted || controller.value.isStreamingImages) return;

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
      print("Error starting stream: $e");
    }
  }

  // Dừng luồng nhận diện (khi chuyển trang)
  Future<void> stopDetection() async {
    setState(() {
      isDetecting = false;
      yoloResults.clear();
    });
    // Không cần stopImageStream ở đây nếu chỉ tạm dừng xử lý,
    // nhưng nếu chuyển trang thì nên để controller tự dispose hoặc pause.
  }

  // Hàm xử lý từng khung hình từ Camera
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

  // --- HÀM TÌM KIẾM CON VẬT (Thay thế cho hàm bị lỗi ở zoo_data) ---
  Animal? _findAnimalByLabel(String label) {
    try {
      // Chuẩn hóa chuỗi: về chữ thường và bỏ khoảng trắng thừa
      final cleanLabel = label.toLowerCase().trim();

      // Tìm trong danh sách zooAnimals được import từ zoo_data.dart
      return zooAnimals.firstWhere(
        (animal) => animal.id.toLowerCase() == cleanLabel,
      );
    } catch (e) {
      // Không tìm thấy
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Màn hình chờ khi đang khởi tạo
    if (!isLoaded || !isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.green),
              SizedBox(height: 10),
              Text("Đang khởi động Camera AI...",
                  style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Preview
          CameraPreview(controller),

          // 2. Các khung nhận diện (Bounding Boxes)
          ...displayBoxesAroundRecognizedObjects(MediaQuery.of(context).size),

          // 3. Hướng dẫn UI
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.center_focus_weak, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    "Quét con vật để nhận diện",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Hàm vẽ khung chữ nhật bao quanh vật thể
  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    if (yoloResults.isEmpty || cameraImage == null) return [];

    // Tính toán tỉ lệ để vẽ khung chính xác trên màn hình
    double factorX = screen.width / (cameraImage!.height);
    double factorY = screen.height / (cameraImage!.width);

    return yoloResults.map((result) {
      // Lấy tọa độ
      double left = result["box"][0] * factorX;
      double top = result["box"][1] * factorY;
      double right = result["box"][2] * factorX;
      double bottom = result["box"][3] * factorY;

      // Lấy tên nhãn (tag) từ AI
      String label = result['tag'];

      // Tìm con vật trong dữ liệu của mình
      Animal? detectedAnimal = _findAnimalByLabel(label);

      // Màu sắc khung: Xanh lá (nếu có trong dữ liệu), Vàng (nếu lạ)
      Color boxColor =
          detectedAnimal != null ? Colors.greenAccent : Colors.yellowAccent;

      return Positioned(
        left: left,
        top: top,
        width: right - left,
        height: bottom - top,
        child: GestureDetector(
          onTap: () {
            // LOGIC KHI BẤM VÀO KHUNG
            if (detectedAnimal != null) {
              // Tạm dừng detect
              isDetecting = false;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AnimalDetailScreen(animal: detectedAnimal),
                ),
              ).then((_) {
                // Tiếp tục detect khi quay lại
                isDetecting = true;
                // Nếu camera bị dừng stream thì start lại (tuỳ device)
                if (!controller.value.isStreamingImages) {
                  startDetection();
                }
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      "Phát hiện '$label' nhưng chưa có thông tin chi tiết!"),
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: boxColor, width: 3.0),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -25, // Đẩy nhãn lên trên khung
                  left: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: boxColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Text(
                      // Nếu tìm thấy thì hiện tên tiếng Việt, không thì hiện tên gốc
                      detectedAnimal?.name ?? label,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}
