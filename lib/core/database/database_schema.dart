/// DDL do banco local SQLite (SQLCipher).
///
/// Princípios:
/// - Mesmas colunas da API (snake_case) para evitar mapeamento na ida/volta
/// - `category_slug` no lugar de `category_id` na tabela `transactions/bills/budgets`:
///   a UI sempre trabalha com slug; o remote datasource resolve slug↔id quando
///   conversa com a API. Mais simples e robusto.
/// - Cada registro carrega 3 campos de sync:
///   * `_sync_status`: synced | pending_create | pending_update | pending_delete
///   * `_local_updated_at`: timestamp da última mudança local (ms)
///   * `_server_updated_at`: timestamp do servidor (ms desde epoch)
/// - `_outbox`: fila de operações pendentes (CRUD) com retry
/// - `_sync_meta`: cursor `last_pulled_at`/`last_pushed_at` por entidade
class DatabaseSchema {
  DatabaseSchema._();

  static const int version = 6;

  static const List<String> createStatements = [
    // ── Cache do usuário logado ────────────────────────────────
    '''
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      email TEXT NOT NULL,
      full_name TEXT NOT NULL,
      display_name TEXT NOT NULL,
      avatar_url TEXT,
      timezone TEXT NOT NULL DEFAULT 'America/Sao_Paulo',
      locale TEXT NOT NULL DEFAULT 'pt-BR',
      currency_code TEXT NOT NULL DEFAULT 'BRL',
      is_active INTEGER NOT NULL DEFAULT 1,
      email_verified INTEGER NOT NULL DEFAULT 0,
      last_login_at TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
    ''',

    // ── Categorias ─────────────────────────────────────────────
    '''
    CREATE TABLE IF NOT EXISTS categories (
      slug TEXT PRIMARY KEY,
      server_id INTEGER,
      user_id TEXT,
      label TEXT NOT NULL,
      icon TEXT,
      color_hex TEXT,
      bg_hex TEXT,
      kind TEXT NOT NULL DEFAULT 'expense',
      is_system INTEGER NOT NULL DEFAULT 0,
      is_archived INTEGER NOT NULL DEFAULT 0,
      sort_order INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      _sync_status TEXT NOT NULL DEFAULT 'synced',
      _local_updated_at INTEGER NOT NULL DEFAULT 0,
      _server_updated_at INTEGER
    )
    ''',
    'CREATE INDEX IF NOT EXISTS idx_categories_user ON categories(user_id)',

    // ── Contas ─────────────────────────────────────────────────
    '''
    CREATE TABLE IF NOT EXISTS accounts (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      name TEXT NOT NULL,
      kind TEXT NOT NULL,
      institution TEXT,
      icon TEXT,
      color_hex TEXT,
      initial_balance REAL NOT NULL DEFAULT 0,
      currency_code TEXT NOT NULL DEFAULT 'BRL',
      is_archived INTEGER NOT NULL DEFAULT 0,
      include_in_total INTEGER NOT NULL DEFAULT 1,
      sort_order INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      _sync_status TEXT NOT NULL DEFAULT 'synced',
      _local_updated_at INTEGER NOT NULL DEFAULT 0,
      _server_updated_at INTEGER
    )
    ''',
    'CREATE INDEX IF NOT EXISTS idx_accounts_user ON accounts(user_id)',

    // ── Cartões ────────────────────────────────────────────────
    '''
    CREATE TABLE IF NOT EXISTS credit_cards (
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
    ''',
    'CREATE INDEX IF NOT EXISTS idx_credit_cards_user ON credit_cards(user_id)',

    // ── Faturas ────────────────────────────────────────────────
    '''
    CREATE TABLE IF NOT EXISTS credit_card_statements (
      id TEXT PRIMARY KEY,
      credit_card_id TEXT NOT NULL,
      reference_month TEXT NOT NULL,
      closing_date TEXT NOT NULL,
      due_date TEXT NOT NULL,
      total_amount REAL NOT NULL DEFAULT 0,
      paid_amount REAL NOT NULL DEFAULT 0,
      status TEXT NOT NULL DEFAULT 'open',
      paid_at TEXT,
      paid_from_account_id TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      _sync_status TEXT NOT NULL DEFAULT 'synced',
      _local_updated_at INTEGER NOT NULL DEFAULT 0,
      _server_updated_at INTEGER
    )
    ''',
    'CREATE INDEX IF NOT EXISTS idx_statements_card ON credit_card_statements(credit_card_id)',

    // ── Parcelamentos fixos do cartão ──────────────────────────
    '''
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
    ''',
    'CREATE INDEX IF NOT EXISTS idx_cc_installments_card ON credit_card_installments(credit_card_id)',
    'CREATE INDEX IF NOT EXISTS idx_cc_installments_user ON credit_card_installments(user_id)',

    // ── Transactions ───────────────────────────────────────────
    '''
    CREATE TABLE IF NOT EXISTS transactions (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      account_id TEXT,
      credit_card_id TEXT,
      credit_card_statement_id TEXT,
      category_slug TEXT NOT NULL,
      bill_id TEXT,
      recurrence_id TEXT,
      parent_transaction_id TEXT,
      transfer_id TEXT,
      description TEXT NOT NULL,
      place TEXT,
      notes TEXT,
      amount REAL NOT NULL,
      kind TEXT NOT NULL,
      occurred_at TEXT NOT NULL,
      installment_number INTEGER,
      installment_total INTEGER,
      is_pending INTEGER NOT NULL DEFAULT 0,
      is_excluded_from_reports INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      _sync_status TEXT NOT NULL DEFAULT 'synced',
      _local_updated_at INTEGER NOT NULL DEFAULT 0,
      _server_updated_at INTEGER
    )
    ''',
    'CREATE INDEX IF NOT EXISTS idx_tx_user_occurred ON transactions(user_id, occurred_at DESC)',
    'CREATE INDEX IF NOT EXISTS idx_tx_sync_status ON transactions(_sync_status)',

    // ── Bills ──────────────────────────────────────────────────
    '''
    CREATE TABLE IF NOT EXISTS bills (
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
    ''',
    'CREATE INDEX IF NOT EXISTS idx_bills_user_due ON bills(user_id, due_date)',

    // ── Transfers ──────────────────────────────────────────────
    '''
    CREATE TABLE IF NOT EXISTS transfers (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      from_account_id TEXT NOT NULL,
      to_account_id TEXT NOT NULL,
      amount REAL NOT NULL,
      fee REAL NOT NULL DEFAULT 0,
      occurred_at TEXT NOT NULL,
      description TEXT,
      notes TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      _sync_status TEXT NOT NULL DEFAULT 'synced',
      _local_updated_at INTEGER NOT NULL DEFAULT 0,
      _server_updated_at INTEGER
    )
    ''',

    // ── Goals ──────────────────────────────────────────────────
    '''
    CREATE TABLE IF NOT EXISTS goals (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      account_id TEXT,
      title TEXT NOT NULL,
      description TEXT,
      target_amount REAL NOT NULL,
      current_amount REAL NOT NULL DEFAULT 0,
      target_date TEXT,
      icon TEXT,
      color_hex TEXT,
      is_completed INTEGER NOT NULL DEFAULT 0,
      completed_at TEXT,
      is_archived INTEGER NOT NULL DEFAULT 0,
      monthly_yield_percent REAL,
      is_cdb INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      _sync_status TEXT NOT NULL DEFAULT 'synced',
      _local_updated_at INTEGER NOT NULL DEFAULT 0,
      _server_updated_at INTEGER
    )
    ''',

    // ── Goal contributions ─────────────────────────────────────
    '''
    CREATE TABLE IF NOT EXISTS goal_contributions (
      id TEXT PRIMARY KEY,
      goal_id TEXT NOT NULL,
      transaction_id TEXT,
      amount REAL NOT NULL,
      contributed_at TEXT NOT NULL,
      note TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      _sync_status TEXT NOT NULL DEFAULT 'synced',
      _local_updated_at INTEGER NOT NULL DEFAULT 0,
      _server_updated_at INTEGER
    )
    ''',

    // ── Budgets ────────────────────────────────────────────────
    '''
    CREATE TABLE IF NOT EXISTS budgets (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      category_slug TEXT NOT NULL,
      reference_month TEXT NOT NULL,
      amount_limit REAL NOT NULL,
      rollover INTEGER NOT NULL DEFAULT 0,
      alert_threshold INTEGER NOT NULL DEFAULT 80,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      _sync_status TEXT NOT NULL DEFAULT 'synced',
      _local_updated_at INTEGER NOT NULL DEFAULT 0,
      _server_updated_at INTEGER
    )
    ''',

    // ── Recurrences ────────────────────────────────────────────
    '''
    CREATE TABLE IF NOT EXISTS recurrences (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      frequency TEXT NOT NULL DEFAULT 'monthly',
      every_n INTEGER NOT NULL DEFAULT 1,
      day_of_month INTEGER,
      day_of_week INTEGER,
      month_of_year INTEGER,
      start_date TEXT NOT NULL,
      end_date TEXT,
      max_occurrences INTEGER,
      last_generated_at TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      _sync_status TEXT NOT NULL DEFAULT 'synced',
      _local_updated_at INTEGER NOT NULL DEFAULT 0,
      _server_updated_at INTEGER
    )
    ''',

    // ── Notifications ──────────────────────────────────────────
    '''
    CREATE TABLE IF NOT EXISTS notifications (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      kind TEXT NOT NULL DEFAULT 'system',
      title TEXT NOT NULL,
      body TEXT,
      related_kind TEXT,
      related_id TEXT,
      scheduled_for TEXT,
      is_read INTEGER NOT NULL DEFAULT 0,
      read_at TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      _sync_status TEXT NOT NULL DEFAULT 'synced',
      _local_updated_at INTEGER NOT NULL DEFAULT 0,
      _server_updated_at INTEGER
    )
    ''',

    // ── Outbox (fila de mudanças pendentes pra API) ────────────
    '''
    CREATE TABLE IF NOT EXISTS _outbox (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      entity TEXT NOT NULL,
      entity_id TEXT NOT NULL,
      operation TEXT NOT NULL,
      payload TEXT NOT NULL,
      attempts INTEGER NOT NULL DEFAULT 0,
      last_error TEXT,
      created_at INTEGER NOT NULL,
      processed_at INTEGER
    )
    ''',
    'CREATE INDEX IF NOT EXISTS idx_outbox_pending ON _outbox(processed_at) WHERE processed_at IS NULL',

    // ── Sync meta (cursor por entidade) ────────────────────────
    '''
    CREATE TABLE IF NOT EXISTS _sync_meta (
      entity TEXT PRIMARY KEY,
      last_pulled_at INTEGER NOT NULL DEFAULT 0,
      last_pushed_at INTEGER NOT NULL DEFAULT 0
    )
    ''',
  ];
}
