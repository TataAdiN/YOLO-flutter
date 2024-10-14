import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';
import 'package:ultralytics_yolo/yolo_model.dart';

class YoloLiveScreen extends StatefulWidget {
  const YoloLiveScreen({super.key});

  @override
  State<YoloLiveScreen> createState() => _YoloLiveState();
}

class _YoloLiveState extends State<YoloLiveScreen> {
  final controller = UltralyticsYoloCameraController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: FutureBuilder<ObjectDetector>(
          future: _initObjectDetectorWithLocalModel(),
          builder: (context, snapshot) {
            final predictor = snapshot.data;
            return predictor == null
                ? Container()
                : Stack(
                    children: [
                      UltralyticsYoloCameraPreview(
                        controller: controller,
                        predictor: predictor,
                        onCameraCreated: () {
                          predictor.loadModel(
                            useGpu: true,
                          );
                        },
                        boundingBoxesColorList: const [Colors.green],
                      ),
                      StreamBuilder<double?>(
                        stream: predictor.inferenceTime,
                        builder: (context, snapshot) {
                          final inferenceTime = snapshot.data;
                          return StreamBuilder<double?>(
                            stream: predictor.fpsRate,
                            builder: (context, snapshot) {
                              final fpsRate = snapshot.data;
                              return Times(
                                inferenceTime: inferenceTime,
                                fpsRate: fpsRate,
                              );
                            },
                          );
                        },
                      ),
                    ],
                  );
          },
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.abc),
          onPressed: () {
            controller.toggleLensDirection();
          },
        ),
      ),
    );
  }

  Future<ObjectDetector> _initObjectDetectorWithLocalModel() async {
    final modelPath = await _copy('assets/yolov8n_int8.tflite');
    final metadataPath = await _copy('assets/yolov8n_meta.yaml');
    final model = LocalYoloModel(
      id: '',
      task: Task.detect,
      format: Format.tflite,
      modelPath: modelPath,
      metadataPath: metadataPath,
    );

    return ObjectDetector(model: model);
  }

  Future<String> _copy(String assetPath) async {
    final path = '${(await getApplicationSupportDirectory()).path}/$assetPath';
    await io.Directory(dirname(path)).create(recursive: true);
    final file = io.File(path);
    if (!await file.exists()) {
      final byteData = await rootBundle.load(assetPath);
      await file.writeAsBytes(byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    }
    return file.path;
  }
}

class Times extends StatelessWidget {
  const Times({
    super.key,
    required this.inferenceTime,
    required this.fpsRate,
  });

  final double? inferenceTime;
  final double? fpsRate;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(
              Radius.circular(10),
            ),
            color: Colors.black54,
          ),
          child: Text(
            '${(inferenceTime ?? 0).toStringAsFixed(1)} ms  -  ${(fpsRate ?? 0).toStringAsFixed(1)} FPS',
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ),
    );
  }
}
