import 'package:get/get.dart';
import '../../../core/database/local_database.dart';
import '../../../core/network/folha_http_client.dart';
import '../../../core/sync/outbox_repository.dart';
import '../../../core/sync/sync_manager.dart';
import '../auth/presentation/controllers/auth_controller.dart';
import 'data/datasources/account_local_datasource.dart';
import 'data/datasources/account_remote_datasource.dart';
import 'data/repositories/account_repository_impl.dart';
import 'domain/repositories/account_repository.dart';
import 'presentation/controllers/accounts_controller.dart';

class AccountsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AccountRemoteDataSource>()) {
      Get.put<AccountRemoteDataSource>(
        AccountRemoteDataSourceImpl(http: Get.find<FolhaHttpClient>()),
      );
    }
    if (!Get.isRegistered<AccountLocalDataSource>()) {
      Get.put<AccountLocalDataSource>(AccountLocalDataSource(Get.find<LocalDatabase>()));
    }
    if (!Get.isRegistered<AccountRepository>()) {
      Get.put<AccountRepository>(
        AccountRepositoryImpl(
          local: Get.find(),
          outbox: Get.find<OutboxRepository>(),
          syncManager: Get.find<SyncManager>(),
          currentUserId: () => Get.find<AuthController>().user.value?.id ?? '',
        ),
      );
    }
    if (!Get.isRegistered<AccountsController>()) {
      Get.put<AccountsController>(
        AccountsController(repository: Get.find()),
        permanent: true,
      );
    }
  }
}
