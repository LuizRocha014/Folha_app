import '../models/user_model.dart';

/// Contrato do datasource remoto — substituível por uma versão Dio real depois.
abstract class AuthRemoteDataSource {
  Future<UserModel> login({required String email, required String password});

  Future<UserModel> signup({
    required String email,
    required String password,
    required String fullName,
    required String cpf,
    required DateTime birthDate,
  });

  Future<bool> verifyEmailCode({required String code});

  Future<void> logout();

  Future<UserModel?> currentUser();
}

/// Implementação **fake** — usar enquanto o backend não existe.
/// Retorna dados mock com latência simulada (Future.delayed).
class AuthRemoteDataSourceFake implements AuthRemoteDataSource {
  UserModel? _session;

  static const _defaultUser = UserModel(
    id: 'u_marina',
    fullName: 'Marina Alves',
    email: 'marina.alves@email.com',
    cpf: '123.456.789-00',
  );

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _session = UserModel(
      id: _defaultUser.id,
      fullName: _defaultUser.fullName,
      email: email,
      cpf: _defaultUser.cpf,
      birthDate: _defaultUser.birthDate,
    );
    return _session!;
  }

  @override
  Future<UserModel> signup({
    required String email,
    required String password,
    required String fullName,
    required String cpf,
    required DateTime birthDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _session = UserModel(
      id: 'u_${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName,
      email: email,
      cpf: cpf,
      birthDate: birthDate,
    );
    return _session!;
  }

  @override
  Future<bool> verifyEmailCode({required String code}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return code.length == 6;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _session = null;
  }

  @override
  Future<UserModel?> currentUser() async => _session;
}
