import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_vision/flutter_vision.dart';

class YoloImageScreen extends StatefulWidget {
  const YoloImageScreen({super.key});

  @override
  State<YoloImageScreen> createState() => _YoloImageScreenState();
}

class _YoloImageScreenState extends State<YoloImageScreen> {
  FlutterVision vision = FlutterVision();
  File? imageFile;
  int imageHeight = 1;
  int imageWidth = 1;
  bool yoloModelLoaded = false;
  List<Map<String, dynamic>> yoloResults = [];

  @override
  void initState() {
    super.initState();
    _loadYoloModel().then((value) {
      setState(() {
        yoloModelLoaded = true;
      });
    });
  }

  Future<void> _loadYoloModel() async {
    await vision.loadYoloModel(
      labels: 'assets/labels.txt',
      modelPath: 'assets/yolov8n.tflite',
      modelVersion: "yolov8",
      quantization: false,
      numThreads: 2,
      useGpu: true,
    );
    setState(() {
      yoloModelLoaded = true;
    });
  }

  _onPickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        imageFile = File(pickedFile.path);
        _yoloOnImage();
      });
    }
  }

  _yoloOnImage() async {
    yoloResults.clear();
    Uint8List byte = await imageFile!.readAsBytes();
    final image = await decodeImageFromList(byte);
    final result = await vision.yoloOnImage(
      bytesList: byte,
      imageHeight: image.height,
      imageWidth: image.width,
      iouThreshold: 0.8,
      confThreshold: 0.4,
      classThreshold: 0.5,
    );
    if (result.isNotEmpty) {
      setState(() {
        imageHeight = image.height;
        imageWidth = image.width;
        yoloResults = result;
      });
    }
  }

  List<Widget> displayYOLODetectionOverImage(Size screen) {
    if (yoloResults.isEmpty) return [];

    double factorX = screen.width / (imageWidth);
    double imgRatio = imageWidth / imageHeight;
    double newWidth = imageWidth * factorX;
    double newHeight = newWidth / imgRatio;
    double factorY = newHeight / (imageHeight);

    // fix miss 50 pixel when using Stack Fit.Expand
    double statusBarHeight = MediaQuery.of(context).padding.top;
    double appBarHeight = kToolbarHeight;
    double availableHeight = screen.height - statusBarHeight - appBarHeight;
    double paddingY = (availableHeight - newHeight) / 2;

    Color colorPick = const Color.fromARGB(255, 50, 233, 30);
    return yoloResults.map((result) {
      return Positioned(
        left: result["box"][0] * factorX,
        top: result["box"][1] * factorY + paddingY,
        width: (result["box"][2] - result["box"][0]) * factorX,
        height: (result["box"][3] - result["box"][1]) * factorY,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10.0)),
            border: Border.all(color: Colors.pink, width: 2.0),
          ),
          child: Text(
            "${result['tag']} ${(result['box'][4] * 100).toStringAsFixed(0)}%",
            style: TextStyle(
              background: Paint()..color = colorPick,
              color: Colors.white,
              fontSize: 18.0,
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    if (!yoloModelLoaded) {
      return const Scaffold(
        body: Center(
          child: Text("YOLO model not loaded, waiting for it"),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Yolo Static Image'),
      ),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            imageFile != null ? Image.file(imageFile!) : const SizedBox(),
            ...displayYOLODetectionOverImage(size),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Pick',
        onPressed: () => _onPickImage(),
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}
