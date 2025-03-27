import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

List<CameraDescription>? cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CameraSegmentationTest(),
    );
  }
}

class CameraSegmentationTest extends StatefulWidget {
  const CameraSegmentationTest({super.key});
  @override
  State<CameraSegmentationTest> createState() => _CameraSegmentationTestState();
}

class _CameraSegmentationTestState extends State<CameraSegmentationTest> {
  CameraController? _controller;
  Interpreter? interpreter;
  bool isDetecting = false;
  String status = "Carregando modelo...";

  @override
  void initState() {
    super.initState();
    _initCamera();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      interpreter = await Interpreter.fromAsset('assets/tflite/deeplabv3_257_mv_gpu.tflite');
      setState(() {
        status = "Modelo carregado! Processando frames...";
      });
    } catch (e) {
      setState(() {
        status = "Erro ao carregar modelo: $e";
      });
    }
  }

  Future<void> _initCamera() async {
    _controller = CameraController(cameras![0], ResolutionPreset.low, enableAudio: false);
    await _controller!.initialize();
    setState(() {});
    _controller!.startImageStream((CameraImage image) {
      if (!isDetecting && interpreter != null) {
        isDetecting = true;
        _simulateDetection();
      }
    });
  }

  void _simulateDetection() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      status = "Chão detectado ✅ (teste simulado)";
    });
    await Future.delayed(const Duration(seconds: 1));
    isDetecting = false;
  }

  @override
  void dispose() {
    _controller?.dispose();
    interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          CameraPreview(_controller!),
          Positioned(
            bottom: 32,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
