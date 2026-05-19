import 'package:equatable/equatable.dart';

enum BillStatus { pending, paid, overdue, received }

extension BillStatusX on BillStatus {
  String get id => switch (this) {
    BillStatus.pending => 'pending',
    BillStatus.paid => 'paid',
    BillStatus.overdue => 'overdue',
    BillStatus.received => 'received',
  };

  static BillStatus parse(String s) => switch (s) {
    'paid' => BillStatus.paid,
    'overdue' => BillStatus.overdue,
    'received' => BillStatus.received,
    _ => BillStatus.pending,
  };
}

class BillEntity extends Equatable {
  final String id;
  final String description;
  final double amount; // > 0 a pagar, < 0 a receber
  final DateTime due;
  final BillStatus status;
  final String? recurring; // 'Mensal' | null

  const BillEntity({
    required this.id,
    required this.description,
    required this.amount,
    required this.due,
    required this.status,
    this.recurring,
  });

  bool get isPayable => amount > 0;
  bool get isSettled =>
      status == BillStatus.paid || status == BillStatus.received;

  BillEntity copyWith({BillStatus? status}) {
    return BillEntity(
      id: id,
      description: description,
      amount: amount,
      due: due,
      status: status ?? this.status,
      recurring: recurring,
    );
  }

  @override
  List<Object?> get props => [
    id,
    description,
    amount,
    due,
    status,
    recurring,
  ];
}
