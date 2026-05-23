import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuração global do app, carregada do `.env` no bootstrap.
class AppConfig {
  AppConfig._({
    required this.apiBaseUrl,
    required this.apiTimeout,
    required this.environment,
    required this.enableNetworkLogs,
  });

  final String apiBaseUrl;
  final Duration apiTimeout;
  final String environment;
  final bool enableNetworkLogs;

  static AppConfig? _instance;
  static AppConfig get I =>
      _instance ?? (throw StateError('AppConfig não inicializado. Chame AppConfig.load() no main.'));

  bool get isProduction => environment.toLowerCase() == 'prod';
  bool get isDevelopment => environment.toLowerCase() == 'dev';

  /// Carrega o `.env` e popula a instância. Idempotente — chame uma vez no `main`.
  static Future<AppConfig> load() async {
    if (_instance != null) return _instance!;
    await dotenv.load(fileName: '.env');

    final baseUrl = dotenv.maybeGet('API_BASE_URL') ?? 'http://10.0.2.2:5002';
    final timeoutSec = int.tryParse(dotenv.maybeGet('API_TIMEOUT_SECONDS') ?? '') ?? 15;
    final env = dotenv.maybeGet('APP_ENV') ?? 'dev';
    final logs = (dotenv.maybeGet('ENABLE_NETWORK_LOGS') ?? 'false').toLowerCase() == 'true';

    _instance = AppConfig._(
      apiBaseUrl: baseUrl,
      apiTimeout: Duration(seconds: timeoutSec),
      environment: env,
      enableNetworkLogs: logs && env != 'prod',
    );
    return _instance!;
  }
}
