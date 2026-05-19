import 'package:get/get.dart';
import '../bills/data/datasources/bill_remote_datasource.dart';
import '../bills/data/repositories/bill_repository_impl.dart';
import '../bills/domain/repositories/bill_repository.dart';
import '../bills/domain/usecases/bill_usecases.dart';
import '../bills/presentation/controllers/bills_controller.dart';
import '../transactions/data/datasources/transaction_remote_datasource.dart';
import '../transactions/data/repositories/transaction_repository_impl.dart';
import '../transactions/domain/repositories/transaction_repository.dart';
import '../transactions/domain/usecases/transaction_usecases.dart';
import '../transactions/presentation/controllers/transactions_controller.dart';
import 'presentation/controllers/shell_controller.dart';

/// Binding do Shell — pluga dados de Transactions e Bills uma única vez.
/// Mantém os controllers como permanentes pra evitar reload quando o usuário
/// alterna entre tabs ou abre o detail.
class ShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<ShellController>(ShellController(), permanent: true);

    // === Transactions ===
    Get.lazyPut<TransactionRemoteDataSource>(
      () => TransactionRemoteDataSourceFake(),
      fenix: true,
    );
    Get.lazyPut<TransactionRepository>(
      () => TransactionRepositoryImpl(remote: Get.find()),
      fenix: true,
    );
    Get.lazyPut(() => ListTransactionsUseCase(Get.find()), fenix: true);
    Get.lazyPut(() => AddTransactionUseCase(Get.find()), fenix: true);

    Get.put<TransactionsController>(
      TransactionsController(listUC: Get.find(), addUC: Get.find()),
      permanent: true,
    );

    // === Bills ===
    Get.lazyPut<BillRemoteDataSource>(
      () => BillRemoteDataSourceFake(),
      fenix: true,
    );
    Get.lazyPut<BillRepository>(
      () => BillRepositoryImpl(remote: Get.find()),
      fenix: true,
    );
    Get.lazyPut(() => ListBillsUseCase(Get.find()), fenix: true);
    Get.lazyPut(() => UpdateBillStatusUseCase(Get.find()), fenix: true);

    Get.put<BillsController>(
      BillsController(listUC: Get.find(), updateUC: Get.find()),
      permanent: true,
    );
  }
}
