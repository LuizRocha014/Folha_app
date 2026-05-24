import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../entities/bill_entity.dart';

abstract class BillRepository {
  Future<Either<Failure, List<BillEntity>>> list();

  Future<Either<Failure, BillEntity>> updateStatus(
    String id,
    BillStatus status,
  );

  Future<Either<Failure, BillEntity>> create({
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
  });

  /// Aplica um pagamento parcial. Se o acumulado pago zerar o saldo,
  /// promove a conta para paid/received automaticamente.
  Future<Either<Failure, BillEntity>> applyPartialPayment({
    required String id,
    required double amountPaid,
  });

  /// Incrementa o valor total da bill em `delta` (positivo soma, negativo
  /// subtrai). Usado para acumular gastos no cartão na fatura aberta.
  Future<Either<Failure, BillEntity>> incrementAmount({
    required String id,
    required double delta,
  });
}
