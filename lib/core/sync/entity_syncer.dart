import 'outbox_repository.dart';

/// Cada módulo (transactions, bills, accounts…) implementa um EntitySyncer
/// para o SyncManager poder orquestrar push + pull em ordem.
abstract class EntitySyncer {
  /// Nome canônico (deve bater com `entity` no outbox).
  String get entityName;

  /// Ordem de execução — menor número roda primeiro. Útil para FKs:
  /// users(0) → accounts(10) → categories(20) → credit_cards(30) →
  /// recurrences(40) → bills(50) → transactions(60) → ...
  int get order;

  /// Busca todos os registros do servidor e merge no banco local.
  /// Estratégia padrão: server overwrite (LWW por `updated_at`).
  Future<void> pullAll();

  /// Processa uma entrada do outbox — POST/PUT/DELETE no servidor.
  /// Deve atualizar o registro local (sync_status='synced', server_updated_at)
  /// ou lançar exceção (o SyncManager registra como falha).
  Future<void> pushEntry(OutboxEntry entry);
}
