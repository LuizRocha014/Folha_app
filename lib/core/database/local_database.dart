import 'dart:developer' as developer;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import '../security/crypto_utils.dart';
import '../security/secure_storage_service.dart';
import 'database_schema.dart';

const String _migrationLog = 'LocalDatabase.migration';

/// LocalDatabase — banco SQLite encriptado (SQLCipher) por usuário.
///
/// Arquivo: `<appData>/folha_<userId>.db`. Chave AES-256 gerada na primeira abertura
/// e guardada em Keychain/Keystore via `SecureStorageService`. Não há fallback —
/// se a chave for perdida, o banco daquele usuário fica inacessível e é descartado.
class LocalDatabase {
  LocalDatabase._(this._userId, this._db);

  final String _userId;
  final Database _db;

  /// Banco aberto e pronto pra queries.
  Database get raw => _db;

  /// Id do usuário dono deste banco — útil para validar acessos cruzados.
  String get userId => _userId;

  /// Abre (ou cria) o banco do usuário informado.
  static Future<LocalDatabase> open({
    required String userId,
    required SecureStorageService secureStorage,
  }) async {
    if (userId.isEmpty) {
      throw ArgumentError('userId obrigatório para abrir o banco local.');
    }

    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'folha_$userId.db');

    var key = await secureStorage.readDatabaseKey(userId);
    if (key == null || key.isEmpty) {
      key = CryptoUtils.newRandomKeyHex();
      await secureStorage.saveDatabaseKey(userId, key);
    }

    final db = await openDatabase(
      path,
      password: key,
      version: DatabaseSchema.version,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        developer.log(
          'onCreate user=$userId version=$version — criando schema inicial',
          name: _migrationLog,
        );
        for (final stmt in DatabaseSchema.createStatements) {
          await _runMigrationStep(db, stmt);
        }
        developer.log(
          'onCreate concluído user=$userId version=$version',
          name: _migrationLog,
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        developer.log(
          'onUpgrade user=$userId $oldVersion → $newVersion — iniciando',
          name: _migrationLog,
        );
        // v1 → v2: campos de rendimento na tabela `goals`.
        if (oldVersion < 2) {
          developer.log('v1 → v2: ajustes em `goals`', name: _migrationLog);
          await _runMigrationStep(
            db,
            'ALTER TABLE goals ADD COLUMN monthly_yield_percent REAL',
          );
          await _runMigrationStep(
            db,
            'ALTER TABLE goals ADD COLUMN is_cdb INTEGER NOT NULL DEFAULT 0',
          );
        }
        // v2 → v3: pagamento parcial + parcelas em `bills`.
        if (oldVersion < 3) {
          developer.log(
            'v2 → v3: pagamento parcial + parcelas em `bills`',
            name: _migrationLog,
          );
          await _runMigrationStep(
            db,
            'ALTER TABLE bills ADD COLUMN paid_amount REAL NOT NULL DEFAULT 0',
          );
          await _runMigrationStep(
            db,
            'ALTER TABLE bills ADD COLUMN installment_current INTEGER',
          );
          await _runMigrationStep(
            db,
            'ALTER TABLE bills ADD COLUMN installment_total INTEGER',
          );
        }
        // v3 → v4: `bills.due_date` passa a aceitar NULL (contas sem
        // vencimento). SQLite não permite alterar NOT NULL via ALTER, então
        // recriamos a tabela copiando os dados.
        if (oldVersion < 4) {
          developer.log(
            'v3 → v4: `bills.due_date` agora aceita NULL — recriando tabela',
            name: _migrationLog,
          );
          await _runMigrationStep(db, 'DROP INDEX IF EXISTS idx_bills_user_due');
          await _runMigrationStep(
            db,
            'ALTER TABLE bills RENAME TO bills_old_v3',
          );
          await _runMigrationStep(db, '''
            CREATE TABLE bills (
              id TEXT PRIMARY KEY,
              user_id TEXT NOT NULL,
              account_id TEXT,
              category_slug TEXT,
              recurrence_id TEXT,
              description TEXT NOT NULL,
              amount REAL NOT NULL,
              kind TEXT NOT NULL DEFAULT 'payable',
              due_date TEXT,
              status TEXT NOT NULL DEFAULT 'pending',
              paid_amount REAL NOT NULL DEFAULT 0,
              paid_at TEXT,
              paid_transaction_id TEXT,
              installment_current INTEGER,
              installment_total INTEGER,
              notes TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              _sync_status TEXT NOT NULL DEFAULT 'synced',
              _local_updated_at INTEGER NOT NULL DEFAULT 0,
              _server_updated_at INTEGER
            )
          ''');
          await _runMigrationStep(db, '''
            INSERT INTO bills (
              id, user_id, account_id, category_slug, recurrence_id,
              description, amount, kind, due_date, status,
              paid_amount, paid_at, paid_transaction_id,
              installment_current, installment_total, notes,
              created_at, updated_at,
              _sync_status, _local_updated_at, _server_updated_at
            )
            SELECT
              id, user_id, account_id, category_slug, recurrence_id,
              description, amount, kind, due_date, status,
              paid_amount, paid_at, paid_transaction_id,
              installment_current, installment_total, notes,
              created_at, updated_at,
              _sync_status, _local_updated_at, _server_updated_at
            FROM bills_old_v3
          ''');
          await _runMigrationStep(db, 'DROP TABLE bills_old_v3');
          await _runMigrationStep(
            db,
            'CREATE INDEX IF NOT EXISTS idx_bills_user_due ON bills(user_id, due_date)',
          );
        }
        // v4 → v5: `credit_cards.account_id` passa a aceitar NULL (cartão sem
        // conta vinculada). SQLite não permite remover NOT NULL via ALTER,
        // então recriamos a tabela copiando os dados.
        if (oldVersion < 5) {
          developer.log(
            'v4 → v5: `credit_cards.account_id` agora aceita NULL — recriando tabela',
            name: _migrationLog,
          );
          await _runMigrationStep(db, 'DROP INDEX IF EXISTS idx_credit_cards_user');
          await _runMigrationStep(
            db,
            'ALTER TABLE credit_cards RENAME TO credit_cards_old_v4',
          );
          await _runMigrationStep(db, '''
            CREATE TABLE credit_cards (
              id TEXT PRIMARY KEY,
              user_id TEXT NOT NULL,
              account_id TEXT,
              name TEXT NOT NULL,
              brand TEXT NOT NULL,
              last_four TEXT,
              credit_limit REAL NOT NULL DEFAULT 0,
              closing_day INTEGER NOT NULL,
              due_day INTEGER NOT NULL,
              is_archived INTEGER NOT NULL DEFAULT 0,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              _sync_status TEXT NOT NULL DEFAULT 'synced',
              _local_updated_at INTEGER NOT NULL DEFAULT 0,
              _server_updated_at INTEGER
            )
          ''');
          await _runMigrationStep(db, '''
            INSERT INTO credit_cards (
              id, user_id, account_id, name, brand, last_four,
              credit_limit, closing_day, due_day, is_archived,
              created_at, updated_at,
              _sync_status, _local_updated_at, _server_updated_at
            )
            SELECT
              id, user_id, account_id, name, brand, last_four,
              credit_limit, closing_day, due_day, is_archived,
              created_at, updated_at,
              _sync_status, _local_updated_at, _server_updated_at
            FROM credit_cards_old_v4
          ''');
          await _runMigrationStep(db, 'DROP TABLE credit_cards_old_v4');
          await _runMigrationStep(
            db,
            'CREATE INDEX IF NOT EXISTS idx_credit_cards_user ON credit_cards(user_id)',
          );
        }
        // v5 → v6: parcelamentos fixos por cartão (`credit_card_installments`).
        if (oldVersion < 6) {
          developer.log(
            'v5 → v6: nova tabela `credit_card_installments`',
            name: _migrationLog,
          );
          await _runMigrationStep(db, '''
            CREATE TABLE IF NOT EXISTS credit_card_installments (
              id TEXT PRIMARY KEY,
              user_id TEXT NOT NULL,
              credit_card_id TEXT NOT NULL,
              description TEXT NOT NULL,
              installment_total INTEGER NOT NULL,
              installments_paid INTEGER NOT NULL DEFAULT 0,
              installment_amount REAL NOT NULL,
              start_date TEXT NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              _sync_status TEXT NOT NULL DEFAULT 'synced',
              _local_updated_at INTEGER NOT NULL DEFAULT 0,
              _server_updated_at INTEGER
            )
          ''');
          await _runMigrationStep(
            db,
            'CREATE INDEX IF NOT EXISTS idx_cc_installments_card ON credit_card_installments(credit_card_id)',
          );
          await _runMigrationStep(
            db,
            'CREATE INDEX IF NOT EXISTS idx_cc_installments_user ON credit_card_installments(user_id)',
          );
        }
        developer.log(
          'onUpgrade concluído user=$userId $oldVersion → $newVersion',
          name: _migrationLog,
        );
      },
    );

    return LocalDatabase._(userId, db);
  }

  Future<void> close() => _db.close();

  /// Executa um statement de migration logando o resumo (tipo de comando +
  /// objeto afetado) e medindo o tempo. Se falhar, loga o erro com o SQL
  /// completo antes de propagar.
  static Future<void> _runMigrationStep(Database db, String sql) async {
    final summary = _summarizeSql(sql);
    final sw = Stopwatch()..start();
    try {
      await db.execute(sql);
      sw.stop();
      developer.log(
        '✓ $summary (${sw.elapsedMilliseconds}ms)',
        name: _migrationLog,
      );
    } catch (e, st) {
      sw.stop();
      developer.log(
        '✗ $summary falhou (${sw.elapsedMilliseconds}ms)\nSQL: $sql',
        name: _migrationLog,
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Extrai `<COMANDO> <OBJETO>` de um statement SQL para logs compactos.
  /// Ex.: `CREATE TABLE bills` ou `ALTER TABLE goals`.
  static String _summarizeSql(String sql) {
    final normalized = sql.trim().replaceAll(RegExp(r'\s+'), ' ');
    final match = RegExp(
      r'^(CREATE\s+(?:UNIQUE\s+)?(?:TABLE|INDEX)(?:\s+IF\s+NOT\s+EXISTS)?|ALTER\s+TABLE|DROP\s+(?:TABLE|INDEX)(?:\s+IF\s+EXISTS)?|INSERT\s+INTO)\s+([^\s(]+)',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (match == null) {
      return normalized.length > 60
          ? '${normalized.substring(0, 60)}…'
          : normalized;
    }
    return '${match.group(1)!.toUpperCase()} ${match.group(2)}';
  }

  /// Limpa todos os dados do banco (mantém schema). Útil em logout "esquecer dados".
  Future<void> wipeAllData() async {
    await _db.transaction((txn) async {
      final tables = await txn.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_metadata'",
      );
      for (final row in tables) {
        final name = row['name'] as String;
        await txn.delete(name);
      }
    });
  }
}
