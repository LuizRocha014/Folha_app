import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/folha_colors.dart';
import '../../../bills/presentation/controllers/bills_controller.dart';
import '../../../bills/presentation/pages/add_bill_sheet.dart';
import '../../../bills/presentation/pages/bills_page.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../transactions/presentation/pages/add_transaction_sheet.dart';
import '../../../transactions/presentation/pages/transactions_page.dart';
import '../controllers/shell_controller.dart';
import '../widgets/folha_tab_bar.dart';

class ShellPage extends GetView<ShellController> {
  const ShellPage({super.key});

  /// Abre o sheet certo baseado no tab atual.
  /// - 0 (Início) e 1 (Movimentos) → adicionar transação
  /// - 2 (Contas) → adicionar conta com `initialKind` conforme A pagar/A receber
  /// - 3 (Perfil) → default: adicionar transação
  void _onAddPressed(BuildContext context, int tabIndex) {
    if (tabIndex == 2) {
      final billsTab = Get.isRegistered<BillsController>()
          ? Get.find<BillsController>().tab.value
          : 'pay';
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: FolhaColors.forest900.withValues(alpha: 0.45),
        builder: (_) => AddBillSheet(
          initialKind: billsTab == 'receive' ? 'receive' : 'pay',
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: FolhaColors.forest900.withValues(alpha: 0.45),
      builder: (_) => const AddTransactionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FolhaColors.paper100,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Obx(() {
              return IndexedStack(
                index: controller.tabIndex.value,
                children: const [
                  DashboardPage(),
                  TransactionsPage(),
                  BillsPage(),
                  ProfilePage(),
                ],
              );
            }),
            Obx(
              () => FolhaTabBar(
                currentIndex: controller.tabIndex.value,
                onTap: controller.goTo,
                onAddPressed: () => _onAddPressed(context, controller.tabIndex.value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
