import 'package:equatable/equatable.dart';

/// Cartão de crédito do usuário.
///
/// `closingDay` / `dueDay` são dias do mês (1..31). O usuário define os dois
/// para o app calcular a fatura corrente.
class CreditCardEntity extends Equatable {
  final String id;
  final String userId;
  final String? accountId;
  final String name;
  final String brand; // visa, master, elo, amex, hiper, other
  final String? lastFour;
  final double creditLimit;
  final int closingDay;
  final int dueDay;
  final bool isArchived;
  final String syncStatus;

  const CreditCardEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.brand,
    required this.creditLimit,
    required this.closingDay,
    required this.dueDay,
    this.accountId,
    this.lastFour,
    this.isArchived = false,
    this.syncStatus = 'synced',
  });

  @override
  List<Object?> get props => [
        id, userId, accountId, name, brand, lastFour,
        creditLimit, closingDay, dueDay, isArchived, syncStatus,
      ];
}
