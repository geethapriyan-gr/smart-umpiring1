import 'package:camera/camera.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  Future<void>? _initializingFuture;

  bool get isInitialized => _isInitialized;
  CameraController? get controller => _controller;

  // Initialize camera
  Future<void> initializeCamera() async {
    if (_isInitialized && _controller?.value.isInitialized == true) {
      return;
    }

    if (_initializingFuture != null) {
      await _initializingFuture;
      return;
    }

    final future = _initializeCameraInternal();
    _initializingFuture = future;

    try {
      await future;
    } finally {
      _initializingFuture = null;
    }
  }

  Future<void> _initializeCameraInternal() async {
    try {
      _cameras ??= await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception('No cameras available');
      }

      await _controller?.dispose();
      _controller = await _buildController(_cameras![0]);
      _isInitialized = true;
    } catch (e) {
      _controller = null;
      _isInitialized = false;
      throw Exception('Failed to initialize camera: $e');
    }
  }

  // Dispose camera
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    _initializingFuture = null;
  }

  // Get available cameras
  Future<List<CameraDescription>> getAvailableCameras() async {
    _cameras ??= await availableCameras();
    return _cameras!;
  }

  // Switch camera (if multiple cameras available)
  Future<void> switchCamera(int cameraIndex) async {
    _cameras ??= await availableCameras();

    if (_cameras == null || cameraIndex >= _cameras!.length) {
      throw Exception('Invalid camera index');
    }

    await _controller?.dispose();
    _controller = await _buildController(_cameras![cameraIndex]);
    _isInitialized = true;
  }

  Future<CameraController> _buildController(
      CameraDescription description) async {
    final controller = CameraController(
      description,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await controller.initialize();
    return controller;
  }
}
