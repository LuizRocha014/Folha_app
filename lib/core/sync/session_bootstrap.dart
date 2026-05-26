import 'dart:async';
import 'package:get/get.dart';
import '../../app/modules/accounts/data/datasources/account_local_datasource.dart';
import '../../app/modules/accounts/data/datasources/account_remote_datasource.dart';
import '../../app/modules/accounts/data/datasources/account_syncer.dart';
import '../../app/modules/bills/data/datasources/bill_local_datasource.dart';
import '../../app/modules/bills/data/datasources/bill_remote_datasource.dart';
import '../../app/modules/bills/data/datasources/bill_syncer.dart';
import '../../app/modules/categories/data/datasources/category_remote_datasource.dart';
import '../../app/modules/categories/data/datasources/category_syncer.dart';
import '../../app/modules/credit_cards/data/datasources/credit_card_installment_local_datasource.dart';
import '../../app/modules/credit_cards/data/datasources/credit_card_installment_remote_datasource.dart';
import '../../app/modules/credit_cards/data/datasources/credit_card_installment_syncer.dart';
import '../../app/modules/credit_cards/data/datasources/credit_card_local_datasource.dart';
import '../../app/modules/credit_cards/data/datasources/credit_card_remote_datasource.dart';
import '../../app/modules/credit_cards/data/datasources/credit_card_syncer.dart';
import '../../app/modules/credit_cards/domain/services/installment_materializer.dart';
import '../../app/modules/transactions/data/datasources/transaction_local_datasource.dart';
import '../../app/modules/transactions/data/datasources/transaction_remote_datasource.dart';
import '../../app/modules/transactions/data/datasources/transaction_syncer.dart';
import '../database/category_lookup.dart';
import '../database/local_database.dart';
import '../network/connectivity_service.dart';
import '../network/folha_http_client.dart';
import 'entity_syncer.dart';
import 'outbox_repository.dart';
import 'pending_reconciler.dart';
import 'secondary_syncers.dart';
import 'sync_manager.dart';
import 'sync_meta_repository.dart';

class SessionBootstrap {
  SessionBootstrap._();

  static bool _booted = false;

  static Future<void> bootstrap() async {
    if (_booted) return;
    if (!Get.isRegistered<LocalDatabase>()) {
      throw StateError('LocalDatabase precisa ter sido aberto antes do bootstrap.');
    }

    final db = Get.find<LocalDatabase>();
    final http = Get.find<FolhaHttpClient>();
    final connectivity = Get.find<ConnectivityService>();

    Get.put<OutboxRepository>(OutboxRepository(db), permanent: true);
    Get.put<CategoryLookup>(CategoryLookup(db), permanent: true);
    Get.put<SyncMetaRepository>(SyncMetaRepository(db), permanent: true);

    final accountRemote = AccountRemoteDataSourceImpl(http: http);
    final accountLocal = AccountLocalDataSource(db);
    final txRemote = TransactionRemoteDataSourceImpl(http: http);
    final txLocal = TransactionLocalDataSource(db);
    final billRemote = BillRemoteDataSourceImpl(http: http);
    final billLocal = BillLocalDataSource(db);
    final categoryRemote = CategoryRemoteDataSourceImpl(http: http);
    final creditCardRemote = CreditCardRemoteDataSourceImpl(http: http);
    final creditCardLocal = CreditCardLocalDataSource(db);
    final installmentRemote = CreditCardInstallmentRemoteDataSourceImpl(http: http);
    final installmentLocal = CreditCardInstallmentLocalDataSource(db);
    final lookup = Get.find<CategoryLookup>();
    final meta = Get.find<SyncMetaRepository>();

    if (!Get.isRegistered<AccountRemoteDataSource>()) {
      Get.put<AccountRemoteDataSource>(accountRemote, permanent: true);
    }
    if (!Get.isRegistered<AccountLocalDataSource>()) {
      Get.put<AccountLocalDataSource>(accountLocal, permanent: true);
    }
    if (!Get.isRegistered<TransactionRemoteDataSource>()) {
      Get.put<TransactionRemoteDataSource>(txRemote, permanent: true);
    }
    if (!Get.isRegistered<TransactionLocalDataSource>()) {
      Get.put<TransactionLocalDataSource>(txLocal, permanent: true);
    }
    if (!Get.isRegistered<BillRemoteDataSource>()) {
      Get.put<BillRemoteDataSource>(billRemote, permanent: true);
    }
    if (!Get.isRegistered<BillLocalDataSource>()) {
      Get.put<BillLocalDataSource>(billLocal, permanent: true);
    }
    if (!Get.isRegistered<CategoryRemoteDataSource>()) {
      Get.put<CategoryRemoteDataSource>(categoryRemote, permanent: true);
    }

    final syncers = <EntitySyncer>[
      AccountSyncer(remote: accountRemote, local: accountLocal, meta: meta),
      CategorySyncer(remote: categoryRemote, lookup: lookup),
      CreditCardSyncer(remote: creditCardRemote, local: creditCardLocal),
      CreditCardInstallmentSyncer(remote: installmentRemote, local: installmentLocal),
      RecurrenceSyncer(http: http, db: db),
      BillSyncer(remote: billRemote, local: billLocal, categories: lookup, meta: meta),
      TransactionSyncer(remote: txRemote, local: txLocal, categories: lookup, meta: meta),
      BudgetSyncer(http: http, db: db),
      GoalSyncer(http: http, db: db),
      NotificationSyncer(http: http, db: db),
    ];

    final reconciler = PendingReconciler(
      db: db,
      outbox: Get.find<OutboxRepository>(),
    );

    final manager = SyncManager(
      outbox: Get.find<OutboxRepository>(),
      connectivity: connectivity,
      syncers: syncers,
      // Roda antes de cada push/sync — resgata cartões/registros órfãos mesmo
      // que o bootstrap não seja reexecutado (ex.: reconexão dispara push).
      reconcilePending: reconciler.run,
    );
    Get.put<SyncManager>(manager, permanent: true);
    manager.start();

    final materializer = InstallmentMaterializer(
      db: db,
      txLocal: txLocal,
      outbox: Get.find<OutboxRepository>(),
      categories: lookup,
      syncManager: manager,
    );
    Get.put<InstallmentMaterializer>(materializer, permanent: true);
    // Roda após CADA full sync (inclusive ao reconectar): com os parcelamentos
    // já baixados, materializa as parcelas vencidas como transações.
    manager.afterSync = materializer.run;

    _booted = true;
    // Sincroniza tudo (reconcile + push em ordem de dependência + pull); o
    // afterSync materializa as parcelas no fim.
    unawaited(manager.runFullSync());
  }

  static Future<void> shutdown() async {
    if (!_booted) return;
    if (Get.isRegistered<SyncManager>()) {
      await Get.find<SyncManager>().stop();
      Get.delete<SyncManager>(force: true);
    }
    if (Get.isRegistered<InstallmentMaterializer>()) Get.delete<InstallmentMaterializer>(force: true);
    if (Get.isRegistered<OutboxRepository>()) Get.delete<OutboxRepository>(force: true);
    if (Get.isRegistered<CategoryLookup>()) Get.delete<CategoryLookup>(force: true);
    if (Get.isRegistered<SyncMetaRepository>()) Get.delete<SyncMetaRepository>(force: true);
    if (Get.isRegistered<AccountRemoteDataSource>()) Get.delete<AccountRemoteDataSource>(force: true);
    if (Get.isRegistered<AccountLocalDataSource>()) Get.delete<AccountLocalDataSource>(force: true);
    if (Get.isRegistered<TransactionRemoteDataSource>()) Get.delete<TransactionRemoteDataSource>(force: true);
    if (Get.isRegistered<TransactionLocalDataSource>()) Get.delete<TransactionLocalDataSource>(force: true);
    if (Get.isRegistered<BillRemoteDataSource>()) Get.delete<BillRemoteDataSource>(force: true);
    if (Get.isRegistered<BillLocalDataSource>()) Get.delete<BillLocalDataSource>(force: true);
    if (Get.isRegistered<CategoryRemoteDataSource>()) Get.delete<CategoryRemoteDataSource>(force: true);
    if (Get.isRegistered<LocalDatabase>()) {
      await Get.find<LocalDatabase>().close();
      Get.delete<LocalDatabase>(force: true);
    }
    _booted = false;
  }
}
