import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

enum ObstacleDirection { left, center, right }

enum ObstacleUrgency { close, veryClose }

class ObstacleAlert {
  final ObstacleDirection direction;
  final ObstacleUrgency urgency;

  ObstacleAlert({required this.direction, required this.urgency});
}

/// Points the rear camera forward and runs on-device object detection to
/// warn about large obstacles (walls, poles, people) roughly in the user's
/// path. This is a supplementary aid, not a substitute for a cane or guide
/// dog: it only sees what the camera sees, needs the phone held with the
/// camera unobstructed and pointed ahead, and can't tell a wall from a
/// person — only that something big is close, and roughly which direction.
class ObstacleDetectionService {
  // Bounding-box area as a fraction of the frame; how "close" something
  // looks. These are rough heuristics and will likely need real-device
  // tuning — there's no true distance measurement here, just apparent size.
  static const double _closeAreaRatio = 0.15;
  static const double _veryCloseAreaRatio = 0.35;

  static const Duration _minAlertInterval = Duration(seconds: 3);
  static const Duration _urgentMinAlertInterval = Duration(milliseconds: 1500);
  static const Duration _detectionInterval = Duration(milliseconds: 500);

  static const Map<DeviceOrientation, int> _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  CameraController? _controller;
  ObjectDetector? _detector;
  bool _isProcessingFrame = false;
  DateTime? _lastFrameProcessedAt;
  DateTime? _lastAlertAt;
  bool _isRunning = false;

  void Function(ObstacleAlert alert)? onObstacle;
  void Function(String message)? onError;

  bool get isRunning => _isRunning;

  Future<bool> start() async {
    if (_isRunning) return true;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        onError?.call('No camera available on this device.');
        return false;
      }
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _detector = ObjectDetector(
        options: ObjectDetectorOptions(
          mode: DetectionMode.stream,
          classifyObjects: false,
          multipleObjects: true,
        ),
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );
      await _controller!.initialize();
      await _controller!.startImageStream(_onFrame);
      _isRunning = true;
      return true;
    } catch (e) {
      onError?.call('Could not start obstacle detection: $e');
      await stop();
      return false;
    }
  }

  void _onFrame(CameraImage image) {
    if (_isProcessingFrame) return;
    final now = DateTime.now();
    if (_lastFrameProcessedAt != null && now.difference(_lastFrameProcessedAt!) < _detectionInterval) {
      return;
    }
    _lastFrameProcessedAt = now;
    _isProcessingFrame = true;
    _processFrame(image).whenComplete(() => _isProcessingFrame = false);
  }

  Future<void> _processFrame(CameraImage image) async {
    final controller = _controller;
    final detector = _detector;
    if (controller == null || detector == null) return;
    final inputImage = _toInputImage(image, controller.description, controller.value.deviceOrientation);
    if (inputImage == null) {
      debugPrint('ObstacleDetection: dropped frame (could not build InputImage) '
          'format=${image.format.raw} planes=${image.planes.length} '
          'deviceOrientation=${controller.value.deviceOrientation}');
      return;
    }
    try {
      final objects = await detector.processImage(inputImage);
      debugPrint('ObstacleDetection: got ${objects.length} object(s) '
          'frame=${image.width}x${image.height}'
          '${objects.isEmpty ? '' : ' ratios=${objects.map((o) => ((o.boundingBox.width * o.boundingBox.height) / (image.width * image.height)).toStringAsFixed(2)).join(',')}'}');
      _evaluate(objects, image.width, image.height);
    } catch (e, st) {
      debugPrint('ObstacleDetection: processImage threw: $e\n$st');
      // Skip a bad frame rather than taking down the whole stream.
    }
  }

  void _evaluate(List<DetectedObject> objects, int frameWidth, int frameHeight) {
    if (objects.isEmpty) return;
    final frameArea = frameWidth * frameHeight;
    if (frameArea == 0) return;

    DetectedObject? largest;
    double largestRatio = 0;
    for (final obj in objects) {
      final ratio = (obj.boundingBox.width * obj.boundingBox.height) / frameArea;
      if (ratio > largestRatio) {
        largestRatio = ratio;
        largest = obj;
      }
    }
    if (largest == null || largestRatio < _closeAreaRatio) return;

    final urgency = largestRatio >= _veryCloseAreaRatio ? ObstacleUrgency.veryClose : ObstacleUrgency.close;
    final centerX = largest.boundingBox.center.dx / frameWidth;
    final direction = centerX < 0.35
        ? ObstacleDirection.left
        : centerX > 0.65
            ? ObstacleDirection.right
            : ObstacleDirection.center;

    final now = DateTime.now();
    final minInterval = urgency == ObstacleUrgency.veryClose ? _urgentMinAlertInterval : _minAlertInterval;
    if (_lastAlertAt != null && now.difference(_lastAlertAt!) < minInterval) return;
    _lastAlertAt = now;
    onObstacle?.call(ObstacleAlert(direction: direction, urgency: urgency));
  }

  InputImage? _toInputImage(CameraImage image, CameraDescription camera, DeviceOrientation deviceOrientation) {
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation = _orientations[deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (camera.sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation = (camera.sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;
    // Expect a single concatenated plane (nv21 on Android, bgra8888 on iOS),
    // which is what imageFormatGroup above requests.
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Future<void> stop() async {
    _isRunning = false;
    final controller = _controller;
    _controller = null;
    try {
      if (controller != null && controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (_) {}
    await controller?.dispose();
    await _detector?.close();
    _detector = null;
    _lastFrameProcessedAt = null;
    _lastAlertAt = null;
  }

  Future<void> dispose() => stop();
}
