import 'package:get/get.dart';
import '../../../core/database/local_database.dart';
import '../../../core/sync/outbox_repository.dart';
import '../../../core/sync/sync_manager.dart';
import 'data/datasources/notification_local_datasource.dart';
import 'presentation/controllers/notifications_controller.dart';

class NotificationsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<NotificationLocalDataSource>()) {
      Get.put<NotificationLocalDataSource>(
        NotificationLocalDataSource(Get.find<LocalDatabase>()),
      );
    }
    if (!Get.isRegistered<NotificationsController>()) {
      Get.put<NotificationsController>(
        NotificationsController(
          local: Get.find(),
          outbox: Get.find<OutboxRepository>(),
          syncManager: Get.find<SyncManager>(),
        ),
      );
    }
  }
}
