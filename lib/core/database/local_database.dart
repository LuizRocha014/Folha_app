import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import '../security/crypto_utils.dart';
import '../security/secure_storage_service.dart';
import 'database_schema.dart';

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
      onCreate: (db, _) async {
        for (final stmt in DatabaseSchema.createStatements) {
          await db.execute(stmt);
        }
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // v1 → v2: campos de rendimento na tabela `goals`.
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE goals ADD COLUMN monthly_yield_percent REAL',
          );
          await db.execute(
            'ALTER TABLE goals ADD COLUMN is_cdb INTEGER NOT NULL DEFAULT 0',
          );
        }
        // v2 → v3: pagamento parcial + parcelas em `bills`.
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE bills ADD COLUMN paid_amount REAL NOT NULL DEFAULT 0',
          );
          await db.execute(
            'ALTER TABLE bills ADD COLUMN installment_current INTEGER',
          );
          await db.execute(
            'ALTER TABLE bills ADD COLUMN installment_total INTEGER',
          );
        }
      },
    );

    return LocalDatabase._(userId, db);
  }

  Future<void> close() => _db.close();

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
