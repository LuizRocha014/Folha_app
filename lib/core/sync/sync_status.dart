/// Constantes dos valores aceitos na coluna `_sync_status` de cada tabela de domínio.
class SyncStatus {
  SyncStatus._();

  static const synced = 'synced';
  static const pendingCreate = 'pending_create';
  static const pendingUpdate = 'pending_update';
  static const pendingDelete = 'pending_delete';

  static bool isPending(String status) =>
      status == pendingCreate || status == pendingUpdate || status == pendingDelete;
}

/// Operações suportadas na fila `_outbox`.
class OutboxOperation {
  OutboxOperation._();

  static const create = 'create';
  static const update = 'update';
  static const delete = 'delete';
}
