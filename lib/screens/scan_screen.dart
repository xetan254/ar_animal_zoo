import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart'; // Import font
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
  bool _isPermissionGranted = false;
  bool isLoaded = false;
  bool isDetecting = false;
  bool isCameraInitialized = false;
  late AnimationController _scanAnimationController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), // Quét nhanh hơn chút
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
    setState(() => isDetecting = true);
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
    if (result.isNotEmpty && mounted) setState(() => yoloResults = result);
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
          CameraPreview(controller),
          _buildScanningAnimation(size),
          ..._buildBoundingBoxes(size),
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 24),
                    decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white24)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.center_focus_weak,
                            color: Colors.greenAccent, size: 20),
                        const SizedBox(width: 10),
                        Text("Di chuyển camera để quét",
                            style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
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
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.green[50], shape: BoxShape.circle),
                child: Icon(Icons.camera_alt_rounded,
                    size: 80, color: Colors.green[700]),
              ),
              const SizedBox(height: 30),
              Text("Cần quyền Camera",
                  style: GoogleFonts.roboto(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              const SizedBox(height: 10),
              Text("Ứng dụng cần sử dụng camera để nhận diện động vật bằng AI.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                      color: Colors.grey[600], fontSize: 16)),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  onPressed: () async {
                    if (await Permission.camera.isPermanentlyDenied) {
                      openAppSettings();
                    } else {
                      _checkPermission();
                    }
                  },
                  child: Text("Cấp quyền ngay",
                      style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              )
            ],
          ),
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
                              AnimalDetailScreen(animal: detectedAnimal)))
                  .then((_) {
                isDetecting = true;
                if (!controller.value.isStreamingImages) startDetection();
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
                  color: mainColor.withValues(alpha: 0.1),
                ),
              ),
              Positioned(
                top: -35,
                left: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: mainColor,
                      borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Icon(
                          detectedAnimal != null
                              ? Icons.pets
                              : Icons.help_outline,
                          size: 14,
                          color: Colors.black),
                      const SizedBox(width: 4),
                      Text(detectedAnimal?.name ?? label.toUpperCase(),
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
    }).toList();
  }
}
