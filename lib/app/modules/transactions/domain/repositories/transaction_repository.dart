import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../entities/transaction_entity.dart';

abstract class TransactionRepository {
  Future<Either<Failure, List<TransactionEntity>>> list();

  Future<Either<Failure, TransactionEntity>> add({
    required String description,
    required String place,
    required String category,
    required double value,
    // Quando esta transação representa o pagamento (parcial ou total) de uma
    // conta fixa, passamos o id da bill e marcamos como excluída dos relatórios
    // — a bill já é a fonte de verdade no gráfico/saldo.
    String? billId,
    bool isExcludedFromReports = false,
    /// Sobrepõe o `kind` inferido por sinal (income/expense). Útil para marcar
    /// pagamento de bill como `transfer_out`/`transfer_in`.
    String? kindOverride,
  });

  Future<Either<Failure, void>> remove(String id);
}
