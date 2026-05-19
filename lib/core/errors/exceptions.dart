/// Exceções da camada de dados (datasource → repository as converte em Failure).
class ServerException implements Exception {
  final String message;
  ServerException([this.message = 'Erro no servidor.']);
}

class CacheException implements Exception {
  final String message;
  CacheException([this.message = 'Erro de cache.']);
}

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'Sem conexão.']);
}

class AuthException implements Exception {
  final String message;
  AuthException([this.message = 'Falha de autenticação.']);
}
