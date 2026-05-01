import 'package:permission_handler/permission_handler.dart';

enum NotificationPermissionStatus { granted, denied, permanentlyDenied }

abstract class NotificationPermissionService {
  Future<NotificationPermissionStatus> checkStatus();
  Future<NotificationPermissionStatus> request();
  Future<bool> openSettings();
}

class LiveNotificationPermissionService implements NotificationPermissionService {
  const LiveNotificationPermissionService();

  @override
  Future<NotificationPermissionStatus> checkStatus() async =>
      _map(await Permission.notification.status);

  @override
  Future<NotificationPermissionStatus> request() async =>
      _map(await Permission.notification.request());

  @override
  Future<bool> openSettings() => openAppSettings();

  NotificationPermissionStatus _map(PermissionStatus status) {
    if (status.isGranted || status.isLimited) {
      return NotificationPermissionStatus.granted;
    }
    if (status.isPermanentlyDenied) {
      return NotificationPermissionStatus.permanentlyDenied;
    }
    return NotificationPermissionStatus.denied;
  }
}
