import '../../../../models/camera_config.dart';

abstract interface class CameraConfigRepository {
  Future<void> savePrimaryConfig(CameraConfig config);
  Future<void> saveSecondaryConfig(CameraConfig config);
  Future<CameraConfig> loadPrimaryConfig();
  Future<CameraConfig> loadSecondaryConfig();
  Future<(CameraConfig, CameraConfig)> loadDualConfig();
  Future<bool> hasPrimaryConfig();
  Future<bool> hasSecondaryConfig();
  Future<bool> hasDualCameraConfig();
  Future<void> clearPrimaryConfig();
  Future<void> clearSecondaryConfig();
  Future<void> clearAllConfigs();
}
