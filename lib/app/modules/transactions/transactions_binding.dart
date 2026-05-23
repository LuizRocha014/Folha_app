import 'package:get/get.dart';
import '../../../core/database/local_database.dart';
import '../../../core/network/folha_http_client.dart';
import '../../../core/sync/outbox_repository.dart';
import '../../../core/sync/sync_manager.dart';
import '../auth/presentation/controllers/auth_controller.dart';
import 'data/datasources/transaction_local_datasource.dart';
import 'data/datasources/transaction_remote_datasource.dart';
import 'data/repositories/transaction_repository_impl.dart';
import 'domain/repositories/transaction_repository.dart';
import 'domain/usecases/transaction_usecases.dart';
import 'presentation/controllers/transactions_controller.dart';

/// Pluga datasources/repositório/controller de transactions.
/// Syncer é registrado pelo SessionBootstrap (precisa de SyncMetaRepository).
class TransactionsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<TransactionRemoteDataSource>()) {
      Get.put<TransactionRemoteDataSource>(
        TransactionRemoteDataSourceImpl(http: Get.find<FolhaHttpClient>()),
      );
    }
    if (!Get.isRegistered<TransactionLocalDataSource>()) {
      Get.put<TransactionLocalDataSource>(
        TransactionLocalDataSource(Get.find<LocalDatabase>()),
      );
    }
    if (!Get.isRegistered<TransactionRepository>()) {
      Get.put<TransactionRepository>(
        TransactionRepositoryImpl(
          local: Get.find(),
          remote: Get.find(),
          outbox: Get.find<OutboxRepository>(),
          syncManager: Get.find<SyncManager>(),
          currentUserId: () => Get.find<AuthController>().user.value?.id ?? '',
        ),
      );
    }

    Get.lazyPut(() => ListTransactionsUseCase(Get.find()));
    Get.lazyPut(() => AddTransactionUseCase(Get.find()));
    Get.lazyPut(() => DeleteTransactionUseCase(Get.find()));

    if (!Get.isRegistered<TransactionsController>()) {
      Get.put<TransactionsController>(
        TransactionsController(
          listUC: Get.find(),
          addUC: Get.find(),
          deleteUC: Get.find(),
          syncManager: Get.find<SyncManager>(),
        ),
        permanent: true,
      );
    }
  }
}
