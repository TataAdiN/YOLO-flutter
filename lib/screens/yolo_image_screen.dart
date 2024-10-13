import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ultralytics_yolo/predict/detect/detect.dart';
import 'package:ultralytics_yolo/yolo_model.dart';

class YoloImageScreen extends StatefulWidget {
  const YoloImageScreen({super.key});

  @override
  State<YoloImageScreen> createState() => _YoloImageScreenState();
}

class _YoloImageScreenState extends State<YoloImageScreen> {
  late LocalYoloModel _model;
  File? imageFile;
  int imageHeight = 1;
  int imageWidth = 1;
  bool yoloModelLoaded = false;
  List<DetectedObject> yoloResults = [];

  @override
  void initState() {
    super.initState();
    _loadYoloModel();
  }

  @override
  void dispose() async {
    super.dispose();
  }

  Future<void> _loadYoloModel() async {
    final modelPath = await _copy('assets/yolov8n_int8.tflite');
    final metadata = await _copy('assets/yolov8n_meta.yaml');
    _model = LocalYoloModel(
        id: '',
        task: Task.detect,
        format: Format.tflite,
        modelPath: modelPath,
        metadataPath: metadata);
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
    final objectDetector = ObjectDetector(model: _model);
    String? model = await objectDetector.loadModel();
    List<DetectedObject?>? detectedObject =
        await objectDetector.detect(imagePath: imageFile!.path);
    List<DetectedObject> ultralysticResults = [];
    for (var result in detectedObject!) {
      ultralysticResults.add(result!);
    }
    Uint8List byte = await imageFile!.readAsBytes();
    final image = await decodeImageFromList(byte);
    setState(() {
      imageHeight = image.height;
      imageWidth = image.width;
      yoloResults = ultralysticResults;
    });
  }

  List<Widget> displayYOLODetectionOverImage(MediaQueryData mediaQuery) {
    if (yoloResults.isEmpty) return [];

    double factorX = mediaQuery.size.width / (imageWidth);
    double imgRatio = imageWidth / imageHeight;
    double newWidth = imageWidth * factorX;
    double newHeight = newWidth / imgRatio;

    // fix miss 50 pixel when using Stack Fit.Expand
    double statusBarHeight = mediaQuery.padding.top;
    double appBarHeight = kToolbarHeight;
    double availableHeight =
        mediaQuery.size.height - statusBarHeight - appBarHeight;
    double paddingY = (availableHeight - newHeight) / 2;

    Color colorPick = const Color.fromARGB(255, 50, 233, 30);
    return yoloResults.map((result) {
      return Positioned(
        left: result.boundingBox.left,
        top: result.boundingBox.top + paddingY,
        width: result.boundingBox.right - result.boundingBox.left,
        height: result.boundingBox.bottom - result.boundingBox.top,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10.0)),
            border: Border.all(color: Colors.pink, width: 2.0),
          ),
          child: Text(
            "${result.label} ${(result.confidence * 100).toStringAsFixed(0)}%",
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

  Future<String> _copy(String assetPath) async {
    final path = '${(await getApplicationSupportDirectory()).path}/$assetPath';
    await Directory(dirname(path)).create(recursive: true);
    final file = File(path);
    if (!await file.exists()) {
      final byteData = await rootBundle.load(assetPath);
      await file.writeAsBytes(byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    }
    return file.path;
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
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
            ...displayYOLODetectionOverImage(mediaQuery),
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
