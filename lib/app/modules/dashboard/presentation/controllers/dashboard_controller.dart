import 'package:get/get.dart';

/// Estado UI específico do Dashboard (esconder saldo, animar chart).
/// Os dados em si vêm do TransactionsController via Get.find().
class DashboardController extends GetxController {
  final RxBool balanceHidden = false.obs;
  final RxBool animateChart = false.obs;

  @override
  void onReady() {
    super.onReady();
    Future.delayed(const Duration(milliseconds: 200), () {
      animateChart.value = true;
    });
  }

  void toggleBalance() => balanceHidden.toggle();
}
