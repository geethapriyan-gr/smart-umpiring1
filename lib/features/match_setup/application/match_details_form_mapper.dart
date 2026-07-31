import '../../../models/camera_config.dart';
import '../../../models/match_details.dart';

class MatchDetailsFormMapper {
  const MatchDetailsFormMapper._();

  static MatchDetails fromForm({
    required String matchName,
    required String team1Name,
    required String team2Name,
    required String oversText,
    required String cameraIp,
    required String cameraUsername,
    required String cameraPassword,
    required bool includeSecondaryCamera,
    required String camera2Ip,
    required String camera2Username,
    required String camera2Password,
  }) {
    return MatchDetails(
      matchName: matchName.trim(),
      team1Name: team1Name.trim(),
      team2Name: team2Name.trim(),
      numberOfOvers: int.parse(oversText.trim()),
      cameraIp: cameraIp.trim(),
      cameraUsername: cameraUsername.trim(),
      cameraPassword: cameraPassword.trim(),
      cameraPort: CameraConfig.defaultPort,
      camera2Ip: includeSecondaryCamera ? camera2Ip.trim() : '',
      camera2Username: includeSecondaryCamera ? camera2Username.trim() : '',
      camera2Password: includeSecondaryCamera ? camera2Password.trim() : '',
      camera2Port: CameraConfig.defaultPort,
    );
  }
}
