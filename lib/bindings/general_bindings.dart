import 'package:get/get.dart';
import 'package:mindheal/features/personalization/controllers/user_controller.dart';

import '../data/services/notifications/notification_service.dart';
import '../features/personalization/controllers/notifcation_controller.dart';
import '../utils/helpers/network_manager.dart';

class GeneralBindings extends Bindings {
  @override
  void dependencies() {
    /// -- Core
    Get.put(NetworkManager());


    /// -- Other
    Get.lazyPut(() => UserController());
    Get.put(TNotificationService());
    Get.lazyPut(() => NotificationController(), fenix: true);
  }
}
