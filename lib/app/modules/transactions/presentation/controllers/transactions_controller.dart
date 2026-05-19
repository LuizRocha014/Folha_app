import 'package:get/get.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/usecases/transaction_usecases.dart';

/// Controller global de transações — alimentado pelo Dashboard e pela tela de Movimentos.
/// Mantido como `permanent: true` no ShellBinding para evitar re-fetch entre tabs.
class TransactionsController extends GetxController {
  final ListTransactionsUseCase listUC;
  final AddTransactionUseCase addUC;

  TransactionsController({required this.listUC, required this.addUC});

  final RxList<TransactionEntity> items = <TransactionEntity>[].obs;
  final RxBool loading = false.obs;
  final RxnString error = RxnString();

  // Filtro: 'all' | 'income' | 'expense' | <categoryId>
  final RxString filter = 'all'.obs;
  final RxString query = ''.obs;

  @override
  void onInit() {
    super.onInit();
    refreshList();
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

  List<TransactionEntity> get filtered {
    var list = items.toList();
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
          .where(
            (t) =>
                t.description.toLowerCase().contains(q) ||
                t.place.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  double get balance {
    return items.fold<double>(0, (a, b) => a + b.value);
  }

  double get weekDelta => 240; // mock — virá do backend

  /// Totais derivados (income/expense/balance) para o hero card.
  ({double income, double expense, double balance}) get totals {
    var income = 0.0;
    var expense = 0.0;
    for (final t in items) {
      if (t.value > 0) {
        income += t.value;
      } else {
        expense += t.value.abs();
      }
    }
    return (income: income, expense: expense, balance: 8420.30);
  }

  /// Spending por categoria (somente saídas).
  Map<String, double> get breakdown {
    final m = <String, double>{};
    for (final t in items) {
      if (t.value < 0) {
        m.update(
          t.category,
          (v) => v + t.value.abs(),
          ifAbsent: () => t.value.abs(),
        );
      }
    }
    return m;
  }
}
