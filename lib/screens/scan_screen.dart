import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart'; // Thư viện chọn ảnh
import 'dart:io';
import '../data/zoo_data.dart';
import 'ar_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  late FlutterVision vision;
  late List<CameraDescription> cameras;
  CameraController? controller;

  bool isLoaded = false;
  bool isDetecting = false;
  List<Map<String, dynamic>> yoloResults = [];
  CameraImage? cameraImage;

  // Biến cho tính năng chọn ảnh
  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;
  Size? _imageSize; // Lưu kích thước ảnh gốc để vẽ box chuẩn

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    cameras = await availableCameras();
    vision = FlutterVision();
    // Load Model YOLO
    await vision.loadYoloModel(
      labels: 'assets/tflite/labels.txt',
      modelPath: 'assets/tflite/yolov8n.tflite',
      modelVersion: "yolov8",
      quantization: false,
      numThreads: 2,
      useGpu: true,
    );

    // Cấu hình Camera độ phân giải cao hơn để quét màn hình tốt hơn
    controller = CameraController(
      cameras[0],
      ResolutionPreset.high, // Tăng lên High
      enableAudio: false,
    );

    await controller!.initialize();
    setState(() {
      isLoaded = true;
    });

    // Bắt đầu stream ngay khi mở
    startDetection();
  }

  // --- LOGIC 1: DETECT TRÊN CAMERA REALTIME ---
  Future<void> startDetection() async {
    if (!isLoaded || isDetecting || _pickedImage != null) return;
    setState(() {
      isDetecting = true;
    });

    await controller!.startImageStream((image) async {
      if (!mounted || _pickedImage != null)
        return; // Dừng nếu đang xem ảnh tĩnh

      cameraImage = image;
      final result = await vision.yoloOnFrame(
        bytesList: image.planes.map((plane) => plane.bytes).toList(),
        imageHeight: image.height,
        imageWidth: image.width,
        iouThreshold: 0.4,
        confThreshold: 0.3, // Giảm xuống 30% để nhạy hơn với màn hình máy tính
        classThreshold: 0.4,
      );

      if (result.isNotEmpty) {
        setState(() {
          yoloResults = result;
        });
      }
    });
  }

  // --- LOGIC 2: DETECT TRÊN ẢNH TĨNH (GALLERY) ---
  Future<void> pickImage() async {
    // 1. Dừng camera stream để tiết kiệm pin
    if (controller != null && controller!.value.isStreamingImages) {
      await controller!.stopImageStream();
    }
    setState(() {
      isDetecting = false;
      yoloResults = [];
    });

    // 2. Chọn ảnh
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      var imageFile = File(image.path);
      var imageBytes = await image.readAsBytes();

      // Lấy kích thước ảnh để vẽ Box cho chuẩn
      var decodedImage = await decodeImageFromList(imageBytes);

      setState(() {
        _pickedImage = imageFile;
        _imageBytes = imageBytes;
        _imageSize =
            Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
      });

      // 3. Chạy AI trên ảnh tĩnh
      final result = await vision.yoloOnImage(
        bytesList: imageBytes,
        imageHeight: decodedImage.height,
        imageWidth: decodedImage.width,
        iouThreshold: 0.4,
        confThreshold: 0.3,
        classThreshold: 0.4,
      );

      setState(() {
        yoloResults = result;
      });
    } else {
      // Nếu hủy chọn, bật lại camera
      startDetection();
    }
  }

  void resetCamera() {
    setState(() {
      _pickedImage = null;
      _imageBytes = null;
      yoloResults = [];
    });
    startDetection();
  }

  @override
  void dispose() {
    controller?.dispose();
    vision.closeYoloModel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoaded)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // 1. LỚP HIỂN THỊ: CAMERA hoặc ẢNH TĨNH
          _pickedImage == null
              ? CameraPreview(controller!)
              : Image.file(_pickedImage!,
                  width: screenSize.width,
                  height: screenSize.height,
                  fit: BoxFit.contain),

          // 2. LỚP VẼ KHUNG (BOUNDING BOX)
          ...displayBoxesAroundRecognizedObjects(screenSize),

          // 3. NÚT CHỨC NĂNG
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Nút chọn ảnh / Reset
                FloatingActionButton(
                  heroTag: "btn1",
                  onPressed: _pickedImage == null ? pickImage : resetCamera,
                  backgroundColor:
                      _pickedImage == null ? Colors.blue : Colors.red,
                  child:
                      Icon(_pickedImage == null ? Icons.image : Icons.refresh),
                ),

                // Hiển thị kết quả & Nút AR
                if (yoloResults.isNotEmpty)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(left: 20),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Phát hiện: ${getTopLabel()}",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.view_in_ar,
                                color: Colors.green),
                            onPressed: () {
                              String label = getTopLabel();
                              Animal? animal = ZooData.getAnimalByLabel(label);
                              if (animal != null) {
                                // Dừng cam trước khi chuyển
                                if (controller!.value.isStreamingImages)
                                  controller!.stopImageStream();
                                Get.to(() => ARScreen(animal: animal));
                              } else {
                                Get.snackbar("Thông báo",
                                    "Chưa có dữ liệu 3D cho con vật này ($label)");
                              }
                            },
                          )
                        ],
                      ),
                    ),
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }

  String getTopLabel() {
    if (yoloResults.isEmpty) return "";
    return yoloResults.first['tag'];
  }

  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    if (yoloResults.isEmpty) return [];

    double factorX = screen.width;
    double factorY = screen.height;

    // Tính tỉ lệ scale dựa trên nguồn ảnh (Camera hay Ảnh tĩnh)
    if (_pickedImage == null) {
      // Logic cho Camera (Lưu ý: Camera thường xoay 90 độ trên Android)
      if (cameraImage != null) {
        factorX = screen.width / (cameraImage!.height);
        factorY = screen.height / (cameraImage!.width);
      }
    } else {
      // Logic cho Ảnh tĩnh
      if (_imageSize != null) {
        // Cần tính toán fit:contain
        double imageRatio = _imageSize!.width / _imageSize!.height;
        double screenRatio = screen.width / screen.height;

        if (imageRatio > screenRatio) {
          // Ảnh rộng hơn màn hình -> fit theo width
          factorX = screen.width / _imageSize!.width;
          factorY = screen.width / _imageSize!.width; // Giữ tỉ lệ
        } else {
          // Ảnh cao hơn màn hình -> fit theo height
          factorX = screen.height / _imageSize!.height;
          factorY = screen.height / _imageSize!.height;
        }
      }
    }

    return yoloResults.map((result) {
      double left = result["box"][0] * factorX;
      double top = result["box"][1] * factorY;
      double right = result["box"][2] * factorX;
      double bottom = result["box"][3] * factorY;

      // Nếu là ảnh tĩnh, cần căn giữa (Offset) vì Image.asset hiển thị ở giữa màn hình
      if (_pickedImage != null && _imageSize != null) {
        // Tính toán vị trí offset để box khớp với ảnh
        double displayedW = _imageSize!.width * factorX;
        double displayedH = _imageSize!.height * factorY;
        double offsetX = (screen.width - displayedW) / 2;
        double offsetY = (screen.height - displayedH) / 2;

        left += offsetX;
        right += offsetX;
        top += offsetY;
        bottom += offsetY;
      }

      return Positioned(
        left: left,
        top: top,
        width: right - left,
        height: bottom - top,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10.0)),
            border: Border.all(color: Colors.red, width: 2.0),
          ),
          child: Text(
            "${result['tag']} ${(result['box'][4] * 100).toStringAsFixed(0)}%",
            style: TextStyle(
              background: Paint()..color = Colors.red,
              color: Colors.white,
              fontSize: 12.0,
            ),
          ),
        ),
      );
    }).toList();
  }
}
