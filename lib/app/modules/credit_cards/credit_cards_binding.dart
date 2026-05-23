import 'package:get/get.dart';
import '../../../core/database/local_database.dart';
import '../../../core/network/folha_http_client.dart';
import '../../../core/sync/outbox_repository.dart';
import '../../../core/sync/sync_manager.dart';
import '../auth/presentation/controllers/auth_controller.dart';
import 'data/datasources/credit_card_local_datasource.dart';
import 'data/datasources/credit_card_remote_datasource.dart';
import 'data/repositories/credit_card_repository_impl.dart';
import 'domain/repositories/credit_card_repository.dart';
import 'domain/usecases/credit_card_usecases.dart';
import 'presentation/controllers/credit_cards_controller.dart';

class CreditCardsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CreditCardRemoteDataSource>()) {
      Get.put<CreditCardRemoteDataSource>(
        CreditCardRemoteDataSourceImpl(http: Get.find<FolhaHttpClient>()),
      );
    }
    if (!Get.isRegistered<CreditCardLocalDataSource>()) {
      Get.put<CreditCardLocalDataSource>(
        CreditCardLocalDataSource(Get.find<LocalDatabase>()),
      );
    }
    if (!Get.isRegistered<CreditCardRepository>()) {
      Get.put<CreditCardRepository>(
        CreditCardRepositoryImpl(
          local: Get.find(),
          outbox: Get.find<OutboxRepository>(),
          syncManager: Get.find<SyncManager>(),
          currentUserId: () => Get.find<AuthController>().user.value?.id ?? '',
        ),
      );
    }

    Get.lazyPut(() => ListCreditCardsUseCase(Get.find()));
    Get.lazyPut(() => CreateCreditCardUseCase(Get.find()));
    Get.lazyPut(() => ArchiveCreditCardUseCase(Get.find()));

    if (!Get.isRegistered<CreditCardsController>()) {
      Get.put<CreditCardsController>(
        CreditCardsController(
          listUC: Get.find(),
          createUC: Get.find(),
          archiveUC: Get.find(),
        ),
      );
    }
  }
}
