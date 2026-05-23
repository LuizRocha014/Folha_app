import 'package:get/get.dart';
import '../../../core/database/local_database.dart';
import '../../../core/network/folha_http_client.dart';
import '../../../core/sync/outbox_repository.dart';
import '../../../core/sync/sync_manager.dart';
import 'data/datasources/goal_local_datasource.dart';
import 'data/datasources/goal_remote_datasource.dart';
import 'presentation/controllers/goals_controller.dart';

class GoalsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<GoalLocalDataSource>()) {
      Get.put<GoalLocalDataSource>(GoalLocalDataSource(Get.find<LocalDatabase>()));
    }
    if (!Get.isRegistered<GoalRemoteDataSource>()) {
      Get.put<GoalRemoteDataSource>(
        GoalRemoteDataSourceImpl(http: Get.find<FolhaHttpClient>()),
      );
    }
    if (!Get.isRegistered<GoalsController>()) {
      Get.put<GoalsController>(
        GoalsController(
          local: Get.find(),
          remote: Get.find(),
          outbox: Get.find<OutboxRepository>(),
          syncManager: Get.find<SyncManager>(),
        ),
      );
    }
  }
}
