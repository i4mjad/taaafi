import 'package:reboot_app_3/core/messaging/repositories/fcm_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'fcm_service.g.dart';

class FCMService {
  final FCMRepository _fcmRepository;

  FCMService(this._fcmRepository);

  Future<String?> getFCMToken() async {
    try {
      return await _fcmRepository.getMessagingToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> updateFCMToken() async {
    try {
      return await _fcmRepository.updateUserMessagingToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }
}

@Riverpod(keepAlive: true)
FCMService fcmService(FcmServiceRef ref) {
  return FCMService(ref.watch(fcmRepositoryProvider));
}
