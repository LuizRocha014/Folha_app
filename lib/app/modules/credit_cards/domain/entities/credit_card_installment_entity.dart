import 'package:equatable/equatable.dart';

/// Plano de parcelamento fixo amarrado a um cartão.
///
/// Guarda o "molde" do parcelamento (ex.: Geladeira em 10x de R$200, 3 já
/// pagas). As parcelas do mês são materializadas como transações normais pelo
/// `InstallmentMaterializer` conforme o cartão vira.
class CreditCardInstallmentEntity extends Equatable {
  final String id;
  final String userId;
  final String creditCardId;
  final String description;

  /// Total de parcelas (N).
  final int installmentTotal;

  /// Parcelas já pagas no momento do cadastro (P). As geradas automaticamente
  /// começam em P+1.
  final int installmentsPaid;

  /// Valor de CADA parcela.
  final double installmentAmount;

  /// Data da 1ª parcela gerada automaticamente (parcela P+1). A partir daqui o
  /// app conta quantas já venceram.
  final DateTime startDate;

  final String syncStatus;

  const CreditCardInstallmentEntity({
    required this.id,
    required this.userId,
    required this.creditCardId,
    required this.description,
    required this.installmentTotal,
    required this.installmentsPaid,
    required this.installmentAmount,
    required this.startDate,
    this.syncStatus = 'synced',
  });

  /// Quantas parcelas faltam, considerando só o ponto de cadastro (sem avanço
  /// temporal). O avanço efetivo é calculado pelo materializer com base no mês.
  int get remainingAtStart => installmentTotal - installmentsPaid;

  @override
  List<Object?> get props => [
        id, userId, creditCardId, description, installmentTotal,
        installmentsPaid, installmentAmount, startDate, syncStatus,
      ];
}
