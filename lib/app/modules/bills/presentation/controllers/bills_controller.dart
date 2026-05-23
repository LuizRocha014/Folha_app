import 'package:get/get.dart';
import '../../../../../core/sync/sync_manager.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../transactions/presentation/controllers/transactions_controller.dart';
import '../../domain/entities/bill_entity.dart';
import '../../domain/usecases/bill_usecases.dart';

class BillsController extends GetxController {
  final ListBillsUseCase listUC;
  final UpdateBillStatusUseCase updateUC;
  final CreateBillUseCase createUC;
  final PayPartialUseCase payPartialUC;
  final SyncManager syncManager;

  BillsController({
    required this.listUC,
    required this.updateUC,
    required this.createUC,
    required this.payPartialUC,
    required this.syncManager,
  });

  final RxList<BillEntity> items = <BillEntity>[].obs;
  final RxBool loading = false.obs;
  final RxnString error = RxnString();

  /// 'pay' (contas a pagar) | 'receive' (a receber).
  final RxString tab = 'pay'.obs;

  // Worker que recarrega a lista quando o sync finaliza —
  // necessário porque o push troca o id local (UUID) pelo id do servidor
  // via `swapId`, e a lista em memória ficaria com o id antigo.
  Worker? _syncWatcher;

  @override
  void onInit() {
    super.onInit();
    refreshList();
    _syncWatcher = ever<bool>(syncManager.syncing, (busy) {
      if (!busy) refreshList();
    });
  }

  @override
  void onClose() {
    _syncWatcher?.dispose();
    super.onClose();
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
    // O valor "pago agora" é o que ainda faltava (`remainingAmount`).
    final amountSettledNow = bill.remainingAmount;
    final r = await updateUC(
      UpdateBillStatusParams(id: id, status: newStatus),
    );
    r.fold((f) => error.value = f.message, (b) async {
      final i = items.indexWhere((it) => it.id == id);
      if (i >= 0) items[i] = b;
      // Registra o pagamento total como transação ligada à bill — aparece
      // nas listas de movimentos mas não entra em relatórios.
      if (amountSettledNow > 0) {
        await _logBillPaymentTx(b, amountSettledNow);
      }
    });
  }

  /// Aplica um pagamento parcial. Retorna a entidade atualizada (saldo restante,
  /// promove para paid quando zera).
  Future<BillEntity?> payPartial(String id, double amount) async {
    final r = await payPartialUC(
      PayPartialParams(billId: id, amount: amount),
    );
    return await r.fold(
      (f) async {
        error.value = f.message;
        return null;
      },
      (b) async {
        final i = items.indexWhere((it) => it.id == id);
        if (i >= 0) items[i] = b;
        // Cada pagamento parcial gera sua própria transação amarrada à bill.
        await _logBillPaymentTx(b, amount);
        return b;
      },
    );
  }

  /// Cria a transação que representa o pagamento (ou recebimento) de uma bill.
  /// Fica marcada como `isExcludedFromReports` para não inflar gráficos/saldo.
  Future<void> _logBillPaymentTx(BillEntity bill, double amountPaid) async {
    if (!Get.isRegistered<TransactionsController>()) return;
    final txCtrl = Get.find<TransactionsController>();
    await txCtrl.recordBillPayment(
      billId: bill.id,
      billDescription: bill.description,
      amountPaid: amountPaid,
      // amount > 0 = a pagar; amount < 0 = a receber.
      isReceivable: bill.amount < 0,
      categorySlug: bill.categorySlug,
    );
  }

  Future<bool> create({
    required String description,
    required double amount,
    required DateTime due,
    required bool isReceivable,
    String? categorySlug,
    String? accountId,
    String? notes,
    String? recurring,
    int? installmentCurrent,
    int? installmentTotal,
  }) async {
    final r = await createUC(CreateBillParams(
      description: description,
      amount: amount,
      due: due,
      isReceivable: isReceivable,
      categorySlug: categorySlug,
      accountId: accountId,
      notes: notes,
      recurring: recurring,
      installmentCurrent: installmentCurrent,
      installmentTotal: installmentTotal,
    ));
    return r.fold(
      (f) {
        error.value = f.message;
        return false;
      },
      (b) {
        items.insert(0, b);
        items.sort((a, b) => a.due.compareTo(b.due));
        return true;
      },
    );
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
      toPay: pending.fold<double>(0, (a, b) => a + b.remainingAmount),
      count: pending.length,
      overdue: overdue,
    );
  }
}
