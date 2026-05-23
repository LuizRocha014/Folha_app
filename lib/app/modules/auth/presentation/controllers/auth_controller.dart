import 'package:get/get.dart';
import '../../../../../core/sync/session_bootstrap.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/biometric_usecases.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/signup_usecase.dart';

class AuthController extends GetxController {
  AuthController({
    required this.loginUC,
    required this.signupUC,
    required this.logoutUC,
    required this.enableBiometricUC,
    required this.disableBiometricUC,
    required this.loginWithBiometricUC,
    required this.restoreSessionUC,
  });

  final LoginUseCase loginUC;
  final SignupUseCase signupUC;
  final LogoutUseCase logoutUC;
  final EnableBiometricUseCase enableBiometricUC;
  final DisableBiometricUseCase disableBiometricUC;
  final LoginWithBiometricUseCase loginWithBiometricUC;
  final RestoreSessionUseCase restoreSessionUC;

  final Rxn<UserEntity> user = Rxn<UserEntity>();
  final RxBool loading = false.obs;
  final RxnString error = RxnString();
  final RxBool biometricEnabled = false.obs;

  bool get isAuthenticated => user.value != null;

  Future<UserEntity?> tryRestoreSession() async {
    loading.value = true;
    final res = await restoreSessionUC(const NoParams());
    loading.value = false;
    return await res.fold(
      (_) async => null,
      (u) async {
        user.value = u;
        if (u != null) {
          await SessionBootstrap.bootstrap();
        }
        return u;
      },
    );
  }

  Future<bool> login({required String email, required String password}) async {
    loading.value = true;
    error.value = null;
    final res = await loginUC(LoginParams(email: email, password: password));
    loading.value = false;
    return await res.fold(
      (f) async {
        error.value = f.message;
        return false;
      },
      (u) async {
        user.value = u;
        await SessionBootstrap.bootstrap();
        return true;
      },
    );
  }

  Future<bool> loginWithBiometric() async {
    loading.value = true;
    error.value = null;
    final res = await loginWithBiometricUC(const NoParams());
    loading.value = false;
    return await res.fold(
      (f) async {
        error.value = f.message;
        return false;
      },
      (u) async {
        user.value = u;
        await SessionBootstrap.bootstrap();
        return true;
      },
    );
  }

  Future<bool> signup({
    required String email,
    required String password,
    required String fullName,
    String? displayName,
    String? cpf,
    DateTime? birthDate,
  }) async {
    loading.value = true;
    error.value = null;
    final res = await signupUC(
      SignupParams(
        email: email,
        password: password,
        fullName: fullName,
        displayName: (displayName?.trim().isNotEmpty ?? false)
            ? displayName!.trim()
            : fullName.trim().split(' ').first,
        cpf: cpf,
        birthDate: birthDate,
      ),
    );
    loading.value = false;
    return await res.fold(
      (f) async {
        error.value = f.message;
        return false;
      },
      (u) async {
        user.value = u;
        await SessionBootstrap.bootstrap();
        return true;
      },
    );
  }

  Future<void> logout() async {
    await SessionBootstrap.shutdown();
    await logoutUC(const NoParams());
    user.value = null;
    biometricEnabled.value = false;
  }

  Future<bool> enableBiometric({required String email, required String password}) async {
    final res = await enableBiometricUC(
      EnableBiometricParams(email: email, password: password),
    );
    return res.fold(
      (f) {
        error.value = f.message;
        return false;
      },
      (_) {
        biometricEnabled.value = true;
        return true;
      },
    );
  }

  Future<void> disableBiometric() async {
    await disableBiometricUC(const NoParams());
    biometricEnabled.value = false;
  }

  Future<void> syncBiometricFlag() async {
    biometricEnabled.value = (Get.isRegistered<dynamic>()) ? biometricEnabled.value : false;
  }
}
