import 'package:ultralytics_yolo/yolo_model.dart';
import 'package:yolo_flutter/ultralytics_patch/ultralytic_platform_interface.dart';

/// Abstract class for all predictors.
abstract class Predictor {
  /// Constructor to create an instance of [Predictor].
  Predictor(this.model);

  /// The model used for prediction.
  final YoloModel model;

  /// The platform instance used to run inference.
  final ultralyticsYoloPlatform = UltralyticPlatformInterface.instance;

  /// The stream of the inference time.
  Stream<double>? get inferenceTime =>
      ultralyticsYoloPlatform.inferenceTimeStream;

  /// The stream of the frames per second (FPS) rate.
  Stream<double>? get fpsRate => ultralyticsYoloPlatform.fpsRateStream;

  /// Loads the model.
  Future<String?> loadModel({bool useGpu = false}) =>
      ultralyticsYoloPlatform.loadModel(model.toJson(), useGpu: useGpu);
}
