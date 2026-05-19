import 'package:equatable/equatable.dart';

class TransactionEntity extends Equatable {
  final String id;
  final String description;
  final String place;
  final String category; // 'food', 'trans', 'leisure', ...
  final double value; // negativo = saída, positivo = entrada
  final DateTime when;
  final String? note;

  const TransactionEntity({
    required this.id,
    required this.description,
    required this.place,
    required this.category,
    required this.value,
    required this.when,
    this.note,
  });

  bool get isIncome => value > 0;

  @override
  List<Object?> get props => [
    id,
    description,
    place,
    category,
    value,
    when,
    note,
  ];
}
