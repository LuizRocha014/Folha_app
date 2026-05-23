import 'package:get/get.dart';
import '../accounts/accounts_binding.dart';
import '../bills/bills_binding.dart';
import '../transactions/transactions_binding.dart';
import 'presentation/controllers/shell_controller.dart';

/// ShellBinding — pluga controllers e datasources das tabs.
/// Cada module binding é idempotente.
class ShellBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ShellController>()) {
      Get.put<ShellController>(ShellController(), permanent: true);
    }
    TransactionsBinding().dependencies();
    BillsBinding().dependencies();
    AccountsBinding().dependencies();
  }
}
