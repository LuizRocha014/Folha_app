import 'package:dio/dio.dart';

/// Wrapper Dio — preparado para quando o backend real existir.
/// Hoje os datasources são fakes; o cliente fica plumbado aguardando baseUrl + interceptors.
class ApiClient {
  final Dio dio;

  ApiClient({String baseUrl = ''})
    : dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 12),
          headers: {'Content-Type': 'application/json'},
        ),
      ) {
    // Quando houver auth real, adicionar interceptor de token aqui.
    // dio.interceptors.add(AuthInterceptor());
  }
}
