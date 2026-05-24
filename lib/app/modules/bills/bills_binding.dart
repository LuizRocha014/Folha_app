import 'package:get/get.dart';
import '../../../core/database/local_database.dart';
import '../../../core/network/folha_http_client.dart';
import '../../../core/sync/outbox_repository.dart';
import '../../../core/sync/sync_manager.dart';
import '../auth/presentation/controllers/auth_controller.dart';
import 'data/datasources/bill_local_datasource.dart';
import 'data/datasources/bill_remote_datasource.dart';
import 'data/repositories/bill_repository_impl.dart';
import 'domain/repositories/bill_repository.dart';
import 'domain/usecases/bill_usecases.dart';
import 'presentation/controllers/bills_controller.dart';

class BillsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<BillRemoteDataSource>()) {
      Get.put<BillRemoteDataSource>(
        BillRemoteDataSourceImpl(http: Get.find<FolhaHttpClient>()),
      );
    }
    if (!Get.isRegistered<BillLocalDataSource>()) {
      Get.put<BillLocalDataSource>(BillLocalDataSource(Get.find<LocalDatabase>()));
    }
    if (!Get.isRegistered<BillRepository>()) {
      Get.put<BillRepository>(
        BillRepositoryImpl(
          local: Get.find(),
          outbox: Get.find<OutboxRepository>(),
          syncManager: Get.find<SyncManager>(),
          currentUserId: () => Get.find<AuthController>().user.value?.id ?? '',
        ),
      );
    }

    Get.lazyPut(() => ListBillsUseCase(Get.find()));
    Get.lazyPut(() => UpdateBillStatusUseCase(Get.find()));
    Get.lazyPut(() => CreateBillUseCase(Get.find()));
    Get.lazyPut(() => PayPartialUseCase(Get.find()));

    if (!Get.isRegistered<BillsController>()) {
      Get.put<BillsController>(
        BillsController(
          listUC: Get.find(),
          updateUC: Get.find(),
          createUC: Get.find(),
          payPartialUC: Get.find(),
          repository: Get.find<BillRepository>(),
          syncManager: Get.find<SyncManager>(),
        ),
        permanent: true,
      );
    }
  }
}
