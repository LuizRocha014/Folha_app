import 'package:get/get.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../domain/entities/bill_entity.dart';
import '../../domain/usecases/bill_usecases.dart';

class BillsController extends GetxController {
  final ListBillsUseCase listUC;
  final UpdateBillStatusUseCase updateUC;

  BillsController({required this.listUC, required this.updateUC});

  final RxList<BillEntity> items = <BillEntity>[].obs;
  final RxBool loading = false.obs;
  final RxnString error = RxnString();

  /// 'pay' (contas a pagar) | 'receive' (a receber).
  final RxString tab = 'pay'.obs;

  @override
  void onInit() {
    super.onInit();
    refreshList();
  }

  Future<void> refreshList() async {
    loading.value = true;
    final r = await listUC(const NoParams());
    r.fold((f) => error.value = f.message, (l) => items.assignAll(l));
    loading.value = false;
  }

  Future<void> markPaid(String id) async {
    final bill = items.firstWhere((b) => b.id == id);
    final newStatus = bill.amount > 0
        ? BillStatus.paid
        : BillStatus.received;
    final r = await updateUC(
      UpdateBillStatusParams(id: id, status: newStatus),
    );
    r.fold((f) => error.value = f.message, (b) {
      final i = items.indexWhere((it) => it.id == id);
      if (i >= 0) items[i] = b;
    });
  }

  List<BillEntity> get filtered =>
      items.where((b) => tab.value == 'pay' ? b.amount > 0 : b.amount < 0).toList();

  ({double toPay, int count, int overdue}) get summary {
    final pending = items.where(
      (b) =>
          b.amount > 0 &&
          (b.status == BillStatus.pending ||
              b.status == BillStatus.overdue),
    );
    final overdue = items.where((b) => b.status == BillStatus.overdue).length;
    return (
      toPay: pending.fold<double>(0, (a, b) => a + b.amount),
      count: pending.length,
      overdue: overdue,
    );
  }
}
