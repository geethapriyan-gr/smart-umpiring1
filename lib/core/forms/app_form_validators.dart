import '../../models/camera_config.dart';

class AppFormValidators {
  const AppFormValidators._();

  static String? requiredText(String? value, String message) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  static String? positiveInteger(
    String? value, {
    required String emptyMessage,
    required String invalidMessage,
  }) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return emptyMessage;
    }

    final parsedValue = int.tryParse(trimmed);
    if (parsedValue == null || parsedValue <= 0) {
      return invalidMessage;
    }

    return null;
  }

  static String? port(
    String? value, {
    required bool requiredField,
  }) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return requiredField ? 'Please enter RTSP port' : null;
    }

    final parsedValue = int.tryParse(trimmed);
    if (parsedValue == null || parsedValue <= 0 || parsedValue > 65535) {
      return 'Invalid port number';
    }

    return null;
  }

  static int parsePort(String? value) {
    return int.tryParse(value?.trim() ?? '') ?? CameraConfig.defaultPort;
  }
}
