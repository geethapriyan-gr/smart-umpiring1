/// Model class for storing camera configuration including IP, username, and password.
class CameraConfig {
  static const int defaultPort = 5554;

  /// The IP address of the camera (without protocol)
  final String ip;

  /// The username for camera authentication
  final String username;

  /// The password for camera authentication
  final String password;

  /// Optional port number (default: 5554)
  final int port;

  /// Creates a new CameraConfig instance.
  CameraConfig({
    required this.ip,
    required this.username,
    required this.password,
    this.port = defaultPort,
  });

  /// Constructs the RTSP URL with authentication credentials.
  ///
  /// Accepts a plain host/IP or a value that already contains an RTSP path.
  /// Username & password are percent-encoded so special characters do not
  /// break preview or FFmpeg recording.
  String get rtspUrl {
    final rawInput = ip.trim();
    if (rawInput.isEmpty) return '';

    final normalizedInput = rawInput.replaceFirst(RegExp(r'^rtsp://'), '');
    final firstSlashIndex = normalizedInput.indexOf('/');
    final authority = firstSlashIndex >= 0
        ? normalizedInput.substring(0, firstSlashIndex)
        : normalizedInput;
    final rawPath =
        firstSlashIndex >= 0 ? normalizedInput.substring(firstSlashIndex) : '/';

    final authorityWithoutCredentials =
        authority.contains('@') ? authority.split('@').last : authority;

    var host = authorityWithoutCredentials;
    var resolvedPort = port;

    final lastColonIndex = authorityWithoutCredentials.lastIndexOf(':');
    if (lastColonIndex > 0 &&
        authorityWithoutCredentials.indexOf(':') == lastColonIndex) {
      final parsedPort = int.tryParse(
          authorityWithoutCredentials.substring(lastColonIndex + 1));
      if (parsedPort != null) {
        host = authorityWithoutCredentials.substring(0, lastColonIndex);
        resolvedPort = parsedPort;
      }
    }

    final encodedUsername = Uri.encodeComponent(username);
    final encodedPassword = Uri.encodeComponent(password);
    final normalizedPath = rawPath.isEmpty ? '/' : rawPath;

    return 'rtsp://$encodedUsername:$encodedPassword@$host:$resolvedPort$normalizedPath';
  }

  /// Creates a copy of this CameraConfig with updated values.
  CameraConfig copyWith({
    String? ip,
    String? username,
    String? password,
    int? port,
  }) {
    return CameraConfig(
      ip: ip ?? this.ip,
      username: username ?? this.username,
      password: password ?? this.password,
      port: port ?? this.port,
    );
  }

  /// Converts this config to a JSON-compatible Map.
  Map<String, dynamic> toMap() {
    return {
      'ip': ip,
      'username': username,
      'password': password,
      'port': port,
    };
  }

  /// Creates a CameraConfig from a Map (e.g., from shared_preferences).
  factory CameraConfig.fromMap(Map<String, dynamic> map) {
    return CameraConfig(
      ip: map['ip'] ?? '',
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      port: map['port'] ?? defaultPort,
    );
  }

  /// Returns an empty CameraConfig with default values.
  factory CameraConfig.empty() {
    return CameraConfig(
      ip: '',
      username: '',
      password: '',
      port: defaultPort,
    );
  }

  /// Checks if this config has valid non-empty values.
  bool get isValid {
    return ip.isNotEmpty && username.isNotEmpty && password.isNotEmpty;
  }

  @override
  String toString() {
    return 'CameraConfig(ip: $ip, port: $port)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CameraConfig &&
        other.ip == ip &&
        other.username == username &&
        other.password == password &&
        other.port == port;
  }

  @override
  int get hashCode {
    return Object.hash(ip, username, password, port);
  }
}
