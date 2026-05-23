import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/credit_card_entity.dart';
import '../repositories/credit_card_repository.dart';

class ListCreditCardsUseCase
    implements UseCase<List<CreditCardEntity>, NoParams> {
  final CreditCardRepository repository;
  ListCreditCardsUseCase(this.repository);

  @override
  Future<Either<Failure, List<CreditCardEntity>>> call(NoParams params) =>
      repository.list();
}

class CreateCreditCardParams extends Equatable {
  final String name;
  final String brand;
  final double creditLimit;
  final int closingDay;
  final int dueDay;
  final String? lastFour;
  final String? accountId;

  const CreateCreditCardParams({
    required this.name,
    required this.brand,
    required this.creditLimit,
    required this.closingDay,
    required this.dueDay,
    this.lastFour,
    this.accountId,
  });

  @override
  List<Object?> get props => [
        name, brand, creditLimit, closingDay, dueDay, lastFour, accountId,
      ];
}

class CreateCreditCardUseCase
    implements UseCase<CreditCardEntity, CreateCreditCardParams> {
  final CreditCardRepository repository;
  CreateCreditCardUseCase(this.repository);

  @override
  Future<Either<Failure, CreditCardEntity>> call(CreateCreditCardParams p) {
    if (p.name.trim().isEmpty) {
      return Future.value(const Left(ValidationFailure('Dê um nome para o cartão.')));
    }
    if (p.creditLimit <= 0) {
      return Future.value(const Left(ValidationFailure('Limite deve ser maior que zero.')));
    }
    if (p.closingDay < 1 || p.closingDay > 31) {
      return Future.value(const Left(ValidationFailure('Dia de fechamento inválido.')));
    }
    if (p.dueDay < 1 || p.dueDay > 31) {
      return Future.value(const Left(ValidationFailure('Dia de vencimento inválido.')));
    }
    return repository.create(
      name: p.name.trim(),
      brand: p.brand,
      creditLimit: p.creditLimit,
      closingDay: p.closingDay,
      dueDay: p.dueDay,
      lastFour: p.lastFour,
      accountId: p.accountId,
    );
  }
}

class ArchiveCreditCardUseCase implements UseCase<void, String> {
  final CreditCardRepository repository;
  ArchiveCreditCardUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String id) => repository.archive(id);
}
