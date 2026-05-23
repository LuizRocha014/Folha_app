import 'package:get/get.dart';
import '../../../../../core/sync/sync_manager.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/usecases/transaction_usecases.dart';

class TransactionsController extends GetxController {
  TransactionsController({
    required this.listUC,
    required this.addUC,
    required this.deleteUC,
    required this.syncManager,
  });

  final ListTransactionsUseCase listUC;
  final AddTransactionUseCase addUC;
  final DeleteTransactionUseCase deleteUC;
  final SyncManager syncManager;

  final RxList<TransactionEntity> items = <TransactionEntity>[].obs;
  final RxBool loading = false.obs;
  final RxnString error = RxnString();

  final RxString filter = 'all'.obs;
  final RxString query = ''.obs;

  // Recarrega quando o sync termina — captura: (a) push trocando UUID local
  // por id do servidor, (b) pull trazendo transações novas de outro device.
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
    error.value = null;
    final res = await listUC(const NoParams());
    res.fold((f) => error.value = f.message, (list) => items.assignAll(list));
    loading.value = false;
  }

  Future<bool> add({
    required String description,
    required String place,
    required String category,
    required double value,
  }) async {
    final res = await addUC(
      AddTransactionParams(
        description: description,
        place: place,
        category: category,
        value: value,
      ),
    );
    return res.fold(
      (f) {
        error.value = f.message;
        return false;
      },
      (tx) {
        items.insert(0, tx);
        return true;
      },
    );
  }

  /// Registra o pagamento de uma conta fixa como movimento ligado ao `billId`.
  ///
  /// A transação aparece nas listagens (Movimentos recentes, tab Movimentos)
  /// mas fica **excluída dos relatórios** — `weekDelta`, gráfico semanal,
  /// balance e totals ignoram esse tipo de movimento porque a conta fixa
  /// já é a fonte de verdade do que foi/será gasto.
  Future<bool> recordBillPayment({
    required String billId,
    required String billDescription,
    required double amountPaid,
    required bool isReceivable,
    String? categorySlug,
  }) async {
    final signed = isReceivable ? amountPaid.abs() : -amountPaid.abs();
    final prefix = isReceivable ? 'Recebimento' : 'Pagamento';
    final res = await (Get.find<TransactionRepository>()).add(
      description: '$prefix: $billDescription',
      place: '—',
      category: categorySlug ?? 'other',
      value: signed,
      billId: billId,
      isExcludedFromReports: true,
      kindOverride: isReceivable ? 'transfer_in' : 'transfer_out',
    );
    return res.fold(
      (f) {
        error.value = f.message;
        return false;
      },
      (tx) {
        items.insert(0, tx);
        return true;
      },
    );
  }

  Future<bool> remove(String id) async {
    final res = await deleteUC(id);
    return res.fold(
      (f) {
        error.value = f.message;
        return false;
      },
      (_) {
        items.removeWhere((t) => t.id == id);
        return true;
      },
    );
  }

  List<TransactionEntity> get filtered {
    var list = items.where((t) => t.syncStatus != 'pending_delete').toList();
    final f = filter.value;
    if (f != 'all') {
      if (f == 'income') {
        list = list.where((t) => t.value > 0).toList();
      } else if (f == 'expense') {
        list = list.where((t) => t.value < 0).toList();
      } else {
        list = list.where((t) => t.category == f).toList();
      }
    }
    if (query.value.isNotEmpty) {
      final q = query.value.toLowerCase();
      list = list
          .where((t) =>
              t.description.toLowerCase().contains(q) ||
              t.place.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  /// Saldo total — exclui transações marcadas como "fora dos relatórios"
  /// (ex.: pagamento de bill, que já é contabilizado na própria bill).
  double get balance => items
      .where((t) => !t.isExcludedFromReports)
      .fold<double>(0, (a, b) => a + b.value);

  /// Saldo líquido dos últimos 7 dias (positivo = ganhou mais do que gastou).
  /// Também ignora transações excluídas de relatórios.
  double get weekDelta {
    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    return items
        .where((t) => !t.isExcludedFromReports && !t.when.isBefore(cutoff))
        .fold<double>(0, (a, b) => a + b.value);
  }

  /// Saída diária dos últimos 7 dias para o gráfico semanal.
  /// Retorna 7 tuplas `(rótulo curto do dia, total de saída no dia)`,
  /// ordem cronológica (mais antigo → hoje).
  ///
  /// Importante: o backend devolve `occurredAt` em UTC. Após o sync,
  /// `t.when` é uma `DateTime` UTC, e usar `t.when.year/month/day` direto
  /// retorna componentes UTC — que podem cair em outro dia local. Por isso
  /// convertemos para o fuso local antes de bucketar.
  List<({String day, double expense})> get last7DaysExpenses {
    const dayLabels = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final buckets = List<double>.filled(7, 0);
    for (final t in items) {
      if (t.value >= 0) continue; // só saídas
      if (t.isExcludedFromReports) continue; // pagamento de bill, etc.
      final localWhen = t.when.toLocal();
      final d = DateTime(localWhen.year, localWhen.month, localWhen.day);
      final diff = today.difference(d).inDays;
      if (diff < 0 || diff > 6) continue;
      buckets[6 - diff] += t.value.abs();
    }
    return List.generate(7, (i) {
      final date = today.subtract(Duration(days: 6 - i));
      return (day: dayLabels[date.weekday % 7], expense: buckets[i]);
    });
  }

  ({double income, double expense, double balance}) get totals {
    var income = 0.0;
    var expense = 0.0;
    for (final t in items) {
      if (t.isExcludedFromReports) continue;
      if (t.value > 0) {
        income += t.value;
      } else {
        expense += t.value.abs();
      }
    }
    return (income: income, expense: expense, balance: balance);
  }

  Map<String, double> get breakdown {
    final m = <String, double>{};
    for (final t in items) {
      if (t.isExcludedFromReports) continue;
      if (t.value < 0) {
        m.update(t.category, (v) => v + t.value.abs(), ifAbsent: () => t.value.abs());
      }
    }
    return m;
  }
}
