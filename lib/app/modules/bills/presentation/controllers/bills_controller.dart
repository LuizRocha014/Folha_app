import 'package:get/get.dart';
import '../../../../../core/sync/sync_manager.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../credit_cards/domain/entities/credit_card_entity.dart';
import '../../../transactions/presentation/controllers/transactions_controller.dart';
import '../../domain/entities/bill_entity.dart';
import '../../domain/repositories/bill_repository.dart';
import '../../domain/usecases/bill_usecases.dart';

class BillsController extends GetxController {
  final ListBillsUseCase listUC;
  final UpdateBillStatusUseCase updateUC;
  final CreateBillUseCase createUC;
  final PayPartialUseCase payPartialUC;
  final BillRepository repository;
  final SyncManager syncManager;

  BillsController({
    required this.listUC,
    required this.updateUC,
    required this.createUC,
    required this.payPartialUC,
    required this.repository,
    required this.syncManager,
  });

  final RxList<BillEntity> items = <BillEntity>[].obs;
  final RxBool loading = false.obs;
  final RxnString error = RxnString();

  /// 'pay' (contas a pagar) | 'receive' (a receber).
  final RxString tab = 'pay'.obs;

  /// Recorte de período/vencimento. Default é `monthDue` — só contas com
  /// data caindo no mês corrente. Os outros valores são `noDue` (avulsas, sem
  /// data) e `all` (sem filtro). Afeta tanto a lista quanto o summary.
  final RxString dateFilter = 'monthDue'.obs;

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
    required DateTime? due,
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
        // Contas sem vencimento vão para o fim da lista — não há ponto de
        // referência cronológico, então ficam abaixo das datadas.
        items.sort((a, b) {
          if (a.due == null && b.due == null) return 0;
          if (a.due == null) return 1;
          if (b.due == null) return -1;
          return a.due!.compareTo(b.due!);
        });
        return true;
      },
    );
  }

  /// `true` se a conta entra no recorte do `dateFilter` atual.
  bool _matchesDateFilter(BillEntity b) {
    switch (dateFilter.value) {
      case 'noDue':
        return b.due == null;
      case 'all':
        return true;
      case 'monthDue':
      default:
        if (b.due == null) return false;
        final now = DateTime.now();
        return b.due!.year == now.year && b.due!.month == now.month;
    }
  }

  List<BillEntity> get filtered => items
      .where((b) => tab.value == 'pay' ? b.amount > 0 : b.amount < 0)
      .where(_matchesDateFilter)
      .toList();

  ({double toPay, int count, int overdue}) get summary {
    final pending = items.where(
      (b) =>
          b.amount > 0 &&
          (b.status == BillStatus.pending ||
              b.status == BillStatus.overdue) &&
          _matchesDateFilter(b),
    );
    final overdue =
        items.where((b) => b.status == BillStatus.overdue && _matchesDateFilter(b)).length;
    return (
      toPay: pending.fold<double>(0, (a, b) => a + b.remainingAmount),
      count: pending.length,
      overdue: overdue,
    );
  }

  /// Label compacto para o card de summary — acompanha o recorte ativo.
  String get summaryEyebrow {
    switch (dateFilter.value) {
      case 'noDue':
        return 'A PAGAR · SEM VENCIMENTO';
      case 'all':
        return 'A PAGAR · TODAS';
      case 'monthDue':
      default:
        return 'A PAGAR ESSE MÊS';
    }
  }

  // ── Cartão de crédito → fatura ───────────────────────────────────────────

  /// Registra um gasto no cartão como parte da fatura corrente daquele cartão.
  /// Se hoje for antes do `closingDay`, a fatura aberta fecha esse mês — soma
  /// o valor nela. Se já passou do fechamento, soma na fatura do mês seguinte.
  /// Cria a fatura se ainda não existir. Devolve o id da bill resultante.
  Future<String?> addCreditCardExpense({
    required CreditCardEntity card,
    required double amount,
    required DateTime spentAt,
  }) async {
    final cycle = _resolveCardCycle(
      closingDay: card.closingDay,
      dueDay: card.dueDay,
      spentAt: spentAt,
    );
    final billDescription = _faturaDescription(card.name, cycle.dueDate);

    // Bill já existente da mesma fatura (mesmo cartão + mesmo vencimento).
    final existing = items.firstWhereOrNull(
      (b) =>
          b.amount > 0 &&
          !b.isSettled &&
          b.description == billDescription &&
          b.due != null &&
          b.due!.year == cycle.dueDate.year &&
          b.due!.month == cycle.dueDate.month &&
          b.due!.day == cycle.dueDate.day,
    );

    if (existing != null) {
      final r = await repository.incrementAmount(id: existing.id, delta: amount);
      return r.fold((f) {
        error.value = f.message;
        return null;
      }, (b) {
        final i = items.indexWhere((it) => it.id == existing.id);
        if (i >= 0) items[i] = b;
        return b.id;
      });
    }

    final ok = await create(
      description: billDescription,
      amount: amount,
      due: cycle.dueDate,
      isReceivable: false,
      categorySlug: 'shop',
      notes: 'Fatura do cartão ${card.name}. Fecha em ${_fmtDate(cycle.closingDate)}.',
      recurring: null,
    );
    if (!ok) return null;
    final created = items.firstWhereOrNull(
      (b) =>
          b.description == billDescription &&
          b.due != null &&
          b.due!.year == cycle.dueDate.year &&
          b.due!.month == cycle.dueDate.month,
    );
    return created?.id;
  }

  /// Retorna a janela da fatura aberta no momento do gasto.
  ({DateTime closingDate, DateTime dueDate}) _resolveCardCycle({
    required int closingDay,
    required int dueDay,
    required DateTime spentAt,
  }) {
    final local = spentAt.toLocal();
    // Se o gasto cai antes do dia de fechamento desse mês, a fatura ainda
    // está aberta e fecha esse mês. Caso contrário, foi pra fatura do mês
    // seguinte (a desse mês já fechou).
    final fechaEsseMes = local.day < closingDay;
    final closingMonth = fechaEsseMes ? local.month : local.month + 1;
    final closingYear = local.year + ((closingMonth - 1) ~/ 12);
    final closingMonthNorm = ((closingMonth - 1) % 12) + 1;
    final closingDate = _clampedDay(closingYear, closingMonthNorm, closingDay);

    // Vencimento: se dueDay < closingDay, vence no mês seguinte ao fechamento.
    final dueOffset = dueDay >= closingDay ? 0 : 1;
    final dueMonthRaw = closingMonthNorm + dueOffset;
    final dueYear = closingYear + ((dueMonthRaw - 1) ~/ 12);
    final dueMonth = ((dueMonthRaw - 1) % 12) + 1;
    final dueDate = _clampedDay(dueYear, dueMonth, dueDay);

    return (closingDate: closingDate, dueDate: dueDate);
  }

  DateTime _clampedDay(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day > lastDay ? lastDay : day);
  }

  String _faturaDescription(String cardName, DateTime dueDate) {
    const meses = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
    ];
    return 'Fatura $cardName · ${meses[dueDate.month - 1]}/${dueDate.year}';
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
