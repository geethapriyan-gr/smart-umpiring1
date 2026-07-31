import '../../../core/forms/app_form_validators.dart';
import '../../../models/camera_config.dart';

class CameraConfigFormMapper {
  const CameraConfigFormMapper._();

  static CameraConfig fromForm({
    required String ip,
    required String username,
    required String password,
    String? portText,
  }) {
    return CameraConfig(
      ip: ip.trim(),
      username: username.trim(),
      password: password.trim(),
      port: AppFormValidators.parsePort(portText),
    );
  }
}
