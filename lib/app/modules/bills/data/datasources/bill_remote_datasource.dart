import '../../domain/entities/bill_entity.dart';
import '../models/bill_model.dart';

abstract class BillRemoteDataSource {
  Future<List<BillModel>> list();
  Future<BillModel> updateStatus(String id, BillStatus status);
}

class BillRemoteDataSourceFake implements BillRemoteDataSource {
  late final List<BillModel> _store = _seed();

  static DateTime _ago(int days) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - days);
  }

  List<BillModel> _seed() => [
    BillModel(
      id: 'b1',
      description: 'Aluguel',
      amount: 1800.00,
      due: _ago(-5),
      status: BillStatus.pending,
      recurring: 'Mensal',
    ),
    BillModel(
      id: 'b2',
      description: 'Cartão Nubank',
      amount: 1240.30,
      due: _ago(-3),
      status: BillStatus.pending,
      recurring: 'Mensal',
    ),
    BillModel(
      id: 'b3',
      description: 'Internet',
      amount: 89.90,
      due: _ago(-1),
      status: BillStatus.overdue,
      recurring: 'Mensal',
    ),
    BillModel(
      id: 'b4',
      description: 'Netflix',
      amount: 39.90,
      due: _ago(-8),
      status: BillStatus.pending,
      recurring: 'Mensal',
    ),
    BillModel(
      id: 'b5',
      description: 'Conta de luz',
      amount: 142.80,
      due: _ago(4),
      status: BillStatus.paid,
      recurring: 'Mensal',
    ),
    BillModel(
      id: 'b6',
      description: 'Cliente A — freela',
      amount: -850,
      due: _ago(6),
      status: BillStatus.received,
    ),
  ];

  @override
  Future<List<BillModel>> list() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return List.unmodifiable(_store);
  }

  @override
  Future<BillModel> updateStatus(String id, BillStatus status) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final i = _store.indexWhere((b) => b.id == id);
    if (i < 0) throw StateError('Bill $id not found');
    final old = _store[i];
    final updated = BillModel(
      id: old.id,
      description: old.description,
      amount: old.amount,
      due: old.due,
      status: status,
      recurring: old.recurring,
    );
    _store[i] = updated;
    return updated;
  }
}
