import 'package:shared_preferences/shared_preferences.dart';

import '../../../../models/camera_config.dart';
import '../../domain/repositories/camera_config_repository.dart';

class SharedPreferencesCameraConfigRepository
    implements CameraConfigRepository {
  static const String _kCameraIp = 'camera_ip';
  static const String _kCameraUsername = 'camera_username';
  static const String _kCameraPassword = 'camera_password';
  static const String _kCameraPort = 'camera_port';

  static const String _kCamera2Ip = 'camera2_ip';
  static const String _kCamera2Username = 'camera2_username';
  static const String _kCamera2Password = 'camera2_password';
  static const String _kCamera2Port = 'camera2_port';

  SharedPreferences? _prefs;

  Future<void> _init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  @override
  Future<void> savePrimaryConfig(CameraConfig config) async {
    await _init();
    await _prefs!.setString(_kCameraIp, config.ip);
    await _prefs!.setString(_kCameraUsername, config.username);
    await _prefs!.setString(_kCameraPassword, config.password);
    await _prefs!.setInt(_kCameraPort, config.port);
  }

  @override
  Future<void> saveSecondaryConfig(CameraConfig config) async {
    await _init();
    await _prefs!.setString(_kCamera2Ip, config.ip);
    await _prefs!.setString(_kCamera2Username, config.username);
    await _prefs!.setString(_kCamera2Password, config.password);
    await _prefs!.setInt(_kCamera2Port, config.port);
  }

  @override
  Future<CameraConfig> loadPrimaryConfig() async {
    await _init();
    return CameraConfig(
      ip: _prefs!.getString(_kCameraIp) ?? '',
      username: _prefs!.getString(_kCameraUsername) ?? '',
      password: _prefs!.getString(_kCameraPassword) ?? '',
      port: _prefs!.getInt(_kCameraPort) ?? CameraConfig.defaultPort,
    );
  }

  @override
  Future<CameraConfig> loadSecondaryConfig() async {
    await _init();
    return CameraConfig(
      ip: _prefs!.getString(_kCamera2Ip) ?? '',
      username: _prefs!.getString(_kCamera2Username) ?? '',
      password: _prefs!.getString(_kCamera2Password) ?? '',
      port: _prefs!.getInt(_kCamera2Port) ?? CameraConfig.defaultPort,
    );
  }

  @override
  Future<(CameraConfig, CameraConfig)> loadDualConfig() async {
    final primaryConfig = await loadPrimaryConfig();
    final secondaryConfig = await loadSecondaryConfig();
    return (primaryConfig, secondaryConfig);
  }

  @override
  Future<bool> hasPrimaryConfig() async {
    await _init();
    return _prefs!.containsKey(_kCameraIp);
  }

  @override
  Future<bool> hasSecondaryConfig() async {
    await _init();
    return _prefs!.containsKey(_kCamera2Ip);
  }

  @override
  Future<bool> hasDualCameraConfig() async {
    await _init();
    return _prefs!.containsKey(_kCameraIp) && _prefs!.containsKey(_kCamera2Ip);
  }

  @override
  Future<void> clearPrimaryConfig() async {
    await _init();
    await _prefs!.remove(_kCameraIp);
    await _prefs!.remove(_kCameraUsername);
    await _prefs!.remove(_kCameraPassword);
    await _prefs!.remove(_kCameraPort);
  }

  @override
  Future<void> clearSecondaryConfig() async {
    await _init();
    await _prefs!.remove(_kCamera2Ip);
    await _prefs!.remove(_kCamera2Username);
    await _prefs!.remove(_kCamera2Password);
    await _prefs!.remove(_kCamera2Port);
  }

  @override
  Future<void> clearAllConfigs() async {
    await clearPrimaryConfig();
    await clearSecondaryConfig();
  }
}
