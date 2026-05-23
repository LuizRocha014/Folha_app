import 'package:equatable/equatable.dart';

/// Movimento financeiro. UI trabalha com `value` (signed) e `category` (slug).
/// O sync com a API traduz pra `amount > 0` + `kind` + `category_id`.
class TransactionEntity extends Equatable {
  /// Id local (UUID) ou id real do servidor quando sync.
  final String id;
  final String userId;
  final String? accountId;
  final String? creditCardId;
  /// Quando preenchido, esta transação é o pagamento de uma `Bill`.
  /// Tipicamente vem com `isExcludedFromReports = true`.
  final String? billId;
  final String description;
  final String place;
  final String category; // slug: food, trans, leisure, …
  final double value; // negativo = saída, positivo = entrada
  final DateTime when;
  final String? note;
  final String kind; // expense | income | transfer_out | transfer_in
  final bool isPending;
  final bool isExcludedFromReports;
  final String syncStatus; // synced | pending_create | pending_update | pending_delete

  const TransactionEntity({
    required this.id,
    required this.userId,
    required this.description,
    required this.place,
    required this.category,
    required this.value,
    required this.when,
    required this.kind,
    this.accountId,
    this.creditCardId,
    this.billId,
    this.note,
    this.isPending = false,
    this.isExcludedFromReports = false,
    this.syncStatus = 'synced',
  });

  bool get isIncome => value > 0;
  bool get isUnsynced => syncStatus != 'synced';

  TransactionEntity copyWith({
    String? id,
    String? userId,
    String? accountId,
    String? creditCardId,
    String? billId,
    String? description,
    String? place,
    String? category,
    double? value,
    DateTime? when,
    String? note,
    String? kind,
    bool? isPending,
    bool? isExcludedFromReports,
    String? syncStatus,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      creditCardId: creditCardId ?? this.creditCardId,
      billId: billId ?? this.billId,
      description: description ?? this.description,
      place: place ?? this.place,
      category: category ?? this.category,
      value: value ?? this.value,
      when: when ?? this.when,
      note: note ?? this.note,
      kind: kind ?? this.kind,
      isPending: isPending ?? this.isPending,
      isExcludedFromReports: isExcludedFromReports ?? this.isExcludedFromReports,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  List<Object?> get props => [
        id, userId, accountId, creditCardId, billId, description, place, category,
        value, when, note, kind, isPending, isExcludedFromReports, syncStatus,
      ];
}
