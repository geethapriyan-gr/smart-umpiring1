import '../../../models/camera_config.dart';
import '../data/repositories/shared_preferences_camera_config_repository.dart';
import '../domain/repositories/camera_config_repository.dart';

class CameraConfigService {
  CameraConfigService({
    CameraConfigRepository? repository,
  }) : _repository = repository ?? SharedPreferencesCameraConfigRepository();

  final CameraConfigRepository _repository;

  Future<void> saveConfig(CameraConfig config) {
    return _repository.savePrimaryConfig(config);
  }

  Future<void> saveCamera2Config(CameraConfig config) {
    return _repository.saveSecondaryConfig(config);
  }

  Future<void> saveDualCameraConfig(
    CameraConfig config1,
    CameraConfig config2,
  ) async {
    await _repository.savePrimaryConfig(config1);
    await _repository.saveSecondaryConfig(config2);
  }

  Future<CameraConfig> loadConfig() {
    return _repository.loadPrimaryConfig();
  }

  Future<CameraConfig> loadCamera2Config() {
    return _repository.loadSecondaryConfig();
  }

  Future<(CameraConfig, CameraConfig)> loadDualConfig() {
    return _repository.loadDualConfig();
  }

  Future<bool> hasConfig() {
    return _repository.hasPrimaryConfig();
  }

  Future<bool> hasCamera2Config() {
    return _repository.hasSecondaryConfig();
  }

  Future<bool> hasDualCameraConfig() {
    return _repository.hasDualCameraConfig();
  }

  Future<void> clearConfig() {
    return _repository.clearPrimaryConfig();
  }

  Future<void> clearCamera2Config() {
    return _repository.clearSecondaryConfig();
  }

  Future<void> clearAllConfigs() {
    return _repository.clearAllConfigs();
  }

  Future<String?> getRtspUrl() async {
    final config = await loadConfig();
    if (config.isValid) {
      return config.rtspUrl;
    }
    return null;
  }

  Future<String?> getCamera2RtspUrl() async {
    final config = await loadCamera2Config();
    if (config.isValid) {
      return config.rtspUrl;
    }
    return null;
  }
}
