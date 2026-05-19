import 'package:get/get.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/signup_usecase.dart';

/// AuthController — sessão de autenticação compartilhada por Welcome/Login/Signup.
/// Permanece em memória (permanent: true via binding) para que o Shell e o
/// Profile consigam ler `currentUser` sem precisar refazer login.
class AuthController extends GetxController {
  final LoginUseCase loginUC;
  final SignupUseCase signupUC;
  final LogoutUseCase logoutUC;

  AuthController({
    required this.loginUC,
    required this.signupUC,
    required this.logoutUC,
  });

  final Rxn<UserEntity> user = Rxn<UserEntity>();
  final RxBool loading = false.obs;
  final RxnString error = RxnString();

  bool get isAuthenticated => user.value != null;

  Future<bool> login({required String email, required String password}) async {
    loading.value = true;
    error.value = null;
    final res = await loginUC(
      LoginParams(email: email, password: password),
    );
    loading.value = false;
    return res.fold(
      (f) {
        error.value = f.message;
        return false;
      },
      (u) {
        user.value = u;
        return true;
      },
    );
  }

  Future<bool> signup({
    required String email,
    required String password,
    required String fullName,
    required String cpf,
    required DateTime birthDate,
  }) async {
    loading.value = true;
    error.value = null;
    final res = await signupUC(
      SignupParams(
        email: email,
        password: password,
        fullName: fullName,
        cpf: cpf,
        birthDate: birthDate,
      ),
    );
    loading.value = false;
    return res.fold(
      (f) {
        error.value = f.message;
        return false;
      },
      (u) {
        user.value = u;
        return true;
      },
    );
  }

  Future<void> logout() async {
    await logoutUC(const NoParams());
    user.value = null;
  }
}
