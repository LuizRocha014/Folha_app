import 'package:get/get.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../bills/bills_binding.dart';
import '../../../bills/presentation/controllers/bills_controller.dart';
import '../../data/datasources/credit_card_installment_local_datasource.dart';
import '../../domain/entities/credit_card_entity.dart';
import '../../domain/repositories/credit_card_installment_repository.dart';
import '../../domain/services/card_invoice.dart';
import '../../domain/services/installment_materializer.dart';
import '../../domain/usecases/credit_card_usecases.dart';

/// Entrada do formulário de parcelamento (parcela X de Y, valor da parcela).
class NewInstallmentInput {
  const NewInstallmentInput({
    required this.description,
    required this.total,
    required this.paid,
    required this.amount,
  });

  final String description;
  final int total;
  final int paid;
  final double amount;
}

class CreditCardsController extends GetxController {
  CreditCardsController({
    required this.listUC,
    required this.createUC,
    required this.archiveUC,
    required this.installmentRepository,
    required this.installmentLocal,
  });

  final ListCreditCardsUseCase listUC;
  final CreateCreditCardUseCase createUC;
  final ArchiveCreditCardUseCase archiveUC;
  final CreditCardInstallmentRepository installmentRepository;
  final CreditCardInstallmentLocalDataSource installmentLocal;

  final RxList<CreditCardEntity> items = <CreditCardEntity>[].obs;
  final RxBool loading = false.obs;
  final RxnString error = RxnString();

  /// Total de parcelas fixas do mês por cartão (cardId → R$). Mostrado no tile.
  final RxMap<String, double> monthInstallments = <String, double>{}.obs;

  @override
  void onInit() {
    super.onInit();
    refreshList();
  }

  Future<void> refreshList() async {
    loading.value = true;
    final r = await listUC(const NoParams());
    r.fold((f) => error.value = f.message, items.assignAll);
    await _loadMonthInstallments();
    loading.value = false;
  }

  Future<void> _loadMonthInstallments() async {
    try {
      final allPlans = await installmentLocal.listAll();
      final byCard = <String, double>{};
      for (final card in items) {
        final plans = allPlans.where((p) => p.creditCardId == card.id).toList();
        if (plans.isEmpty) continue;
        final invoice = CardInvoiceCalculator.compute(
          closingDay: card.closingDay,
          plans: plans,
          cardTransactions: const [],
        );
        byCard[card.id] = invoice.parcelasDoMes;
      }
      monthInstallments.assignAll(byCard);
      // Força os tiles (Obx observa `items`) a reconstruir já com o valor do mês,
      // que é calculado depois da lista ser montada.
      items.refresh();
    } catch (_) {
      // Tile sem o valor do mês não é crítico.
    }
  }

  Future<bool> create({
    required String name,
    required String brand,
    required double creditLimit,
    required int closingDay,
    required int dueDay,
    String? lastFour,
    String? accountId,
    List<NewInstallmentInput> installments = const [],
  }) async {
    final r = await createUC(CreateCreditCardParams(
      name: name,
      brand: brand,
      creditLimit: creditLimit,
      closingDay: closingDay,
      dueDay: dueDay,
      lastFour: lastFour,
      accountId: accountId,
    ));

    CreditCardEntity? created;
    final ok = r.fold(
      (f) {
        error.value = f.message;
        return false;
      },
      (card) {
        created = card;
        items.insert(0, card);
        return true;
      },
    );
    if (!ok || created == null) return false;

    // Parcelamentos começam a vencer a partir do mês corrente (parcela P+1).
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    for (final inp in installments) {
      final res = await installmentRepository.create(
        creditCardId: created!.id,
        description: inp.description,
        installmentTotal: inp.total,
        installmentsPaid: inp.paid,
        installmentAmount: inp.amount,
        startDate: startDate,
      );
      // Não falha o cadastro do cartão por causa de um parcelamento — só registra.
      res.fold((f) => error.value = f.message, (_) {});
    }

    // Gera já a parcela do mês corrente como transação, se houver.
    if (installments.isNotEmpty && Get.isRegistered<InstallmentMaterializer>()) {
      await Get.find<InstallmentMaterializer>().run();
    }
    await _loadMonthInstallments();

    // Cria automaticamente a conta a pagar "Fatura <Cartão> · Mês" com as
    // parcelas do mês, usando a data de fechamento/vencimento do cartão.
    final monthAmount = monthInstallments[created!.id] ?? 0;
    if (monthAmount > 0) {
      await _ensureFaturaBill(created!, monthAmount);
    }
    return true;
  }

  /// Garante a "Fatura do Cartão · Mês" (conta a pagar) com o valor das parcelas
  /// do mês. Reaproveita a lógica de ciclo (fechamento → vencimento) já usada
  /// quando há gasto no cartão. O vencimento segue o `closingDay`/`dueDay`.
  Future<void> _ensureFaturaBill(CreditCardEntity card, double monthAmount) async {
    try {
      if (!Get.isRegistered<BillsController>()) {
        BillsBinding().dependencies();
      }
      final bills = Get.find<BillsController>();
      await bills.addCreditCardExpense(
        card: card,
        amount: monthAmount,
        spentAt: DateTime.now(),
      );
    } catch (e) {
      error.value = 'Cartão criado, mas não consegui montar a fatura: $e';
    }
  }

  Future<void> archive(String id) async {
    final r = await archiveUC(id);
    r.fold(
      (f) => error.value = f.message,
      (_) => items.removeWhere((c) => c.id == id),
    );
  }

  double get totalLimit =>
      items.fold<double>(0, (sum, c) => sum + c.creditLimit);
}
