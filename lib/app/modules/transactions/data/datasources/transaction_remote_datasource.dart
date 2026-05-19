import '../models/transaction_model.dart';

abstract class TransactionRemoteDataSource {
  Future<List<TransactionModel>> list();
  Future<TransactionModel> add({
    required String description,
    required String place,
    required String category,
    required double value,
  });
  Future<void> remove(String id);
}

/// Implementação **fake** com dados mock idênticos ao protótipo Folha.
class TransactionRemoteDataSourceFake implements TransactionRemoteDataSource {
  late final List<TransactionModel> _store = _seed();

  static DateTime _ago(int days, [int h = 12, int m = 0]) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - days, h, m);
  }

  List<TransactionModel> _seed() => [
    TransactionModel(
      id: 't1',
      description: 'Açaí na hora',
      place: 'iFood',
      category: 'food',
      value: -32.50,
      when: _ago(0, 14, 32),
    ),
    TransactionModel(
      id: 't2',
      description: 'Uber até o trabalho',
      place: 'Uber',
      category: 'trans',
      value: -18.90,
      when: _ago(0, 8, 15),
    ),
    TransactionModel(
      id: 't3',
      description: 'Café da manhã',
      place: 'Padaria Lina',
      category: 'food',
      value: -14.00,
      when: _ago(0, 7, 40),
    ),
    TransactionModel(
      id: 't4',
      description: 'Cinema com Júlia',
      place: 'Cinemark',
      category: 'leisure',
      value: -56.00,
      when: _ago(1, 19, 50),
    ),
    TransactionModel(
      id: 't5',
      description: 'Mercado da semana',
      place: 'Pão de Açúcar',
      category: 'food',
      value: -187.40,
      when: _ago(1, 18, 12),
    ),
    TransactionModel(
      id: 't6',
      description: 'Salário — Outubro',
      place: 'Empresa XYZ',
      category: 'income',
      value: 4200.00,
      when: _ago(2, 9, 0),
      note: 'Salário do mês — primeira coisa: separar pra reserva.',
    ),
    TransactionModel(
      id: 't7',
      description: 'Pilates',
      place: 'Studio Equilíbrio',
      category: 'health',
      value: -180.00,
      when: _ago(2, 7, 0),
    ),
    TransactionModel(
      id: 't8',
      description: 'Camiseta linho',
      place: 'Reserva',
      category: 'shop',
      value: -149.00,
      when: _ago(3, 16, 22),
    ),
    TransactionModel(
      id: 't9',
      description: 'Conta de luz',
      place: 'Enel',
      category: 'home',
      value: -142.80,
      when: _ago(4, 11, 0),
    ),
    TransactionModel(
      id: 't10',
      description: 'Almoço com Júlia',
      place: 'Tordesilhas',
      category: 'food',
      value: -78.00,
      when: _ago(4, 13, 30),
      note: 'Vale a pena — bom encontrar gente boa.',
    ),
    TransactionModel(
      id: 't11',
      description: 'Spotify',
      place: 'Assinatura',
      category: 'leisure',
      value: -21.90,
      when: _ago(5, 6, 0),
    ),
    TransactionModel(
      id: 't12',
      description: 'Freela design',
      place: 'Cliente A',
      category: 'income',
      value: 850.00,
      when: _ago(6, 14, 0),
    ),
  ];

  @override
  Future<List<TransactionModel>> list() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return List.unmodifiable(_store);
  }

  @override
  Future<TransactionModel> add({
    required String description,
    required String place,
    required String category,
    required double value,
  }) async {
    await Future.delayed(const Duration(milliseconds: 350));
    final tx = TransactionModel(
      id: 't_${DateTime.now().millisecondsSinceEpoch}',
      description: description,
      place: place,
      category: category,
      value: value,
      when: DateTime.now(),
    );
    _store.insert(0, tx);
    return tx;
  }

  @override
  Future<void> remove(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _store.removeWhere((t) => t.id == id);
  }
}
