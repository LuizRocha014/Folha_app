import 'package:get/get.dart';
import '../../../core/database/local_database.dart';
import '../../../core/network/folha_http_client.dart';
import '../../../core/security/biometric_service.dart';
import '../../../core/security/secure_storage_service.dart';
import 'data/datasources/auth_local_datasource.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/usecases/biometric_usecases.dart';
import 'domain/usecases/login_usecase.dart';
import 'domain/usecases/logout_usecase.dart';
import 'domain/usecases/resend_code_usecase.dart';
import 'domain/usecases/signup_usecase.dart';
import 'domain/usecases/verify_email_usecase.dart';
import 'presentation/controllers/auth_controller.dart';
import 'presentation/controllers/signup_controller.dart';

/// Binding de auth — data layer + use cases + controllers.
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Data layer
    Get.lazyPut<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(http: Get.find<FolhaHttpClient>()),
      fenix: true,
    );
    Get.lazyPut<AuthLocalDataSource>(
      () => AuthLocalDataSource(secureStorage: Get.find<SecureStorageService>()),
      fenix: true,
    );
    Get.lazyPut<AuthRepository>(
      () => AuthRepositoryImpl(
        remote: Get.find(),
        local: Get.find(),
        secureStorage: Get.find<SecureStorageService>(),
        biometric: Get.find<BiometricService>(),
        onDatabaseOpened: (userId) async {
          final db = await LocalDatabase.open(
            userId: userId,
            secureStorage: Get.find<SecureStorageService>(),
          );
          if (Get.isRegistered<LocalDatabase>()) {
            await Get.find<LocalDatabase>().close();
            Get.delete<LocalDatabase>(force: true);
          }
          Get.put<LocalDatabase>(db, permanent: true);
          return db;
        },
      ),
      fenix: true,
    );

    // UseCases
    Get.lazyPut(() => LoginUseCase(Get.find()), fenix: true);
    Get.lazyPut(() => RegisterUseCase(Get.find()), fenix: true);
    Get.lazyPut(() => VerifyEmailUseCase(Get.find()), fenix: true);
    Get.lazyPut(() => ResendCodeUseCase(Get.find()), fenix: true);
    Get.lazyPut(() => LogoutUseCase(Get.find()), fenix: true);
    Get.lazyPut(() => EnableBiometricUseCase(Get.find()), fenix: true);
    Get.lazyPut(() => DisableBiometricUseCase(Get.find()), fenix: true);
    Get.lazyPut(() => LoginWithBiometricUseCase(Get.find()), fenix: true);
    Get.lazyPut(() => RestoreSessionUseCase(Get.find()), fenix: true);

    // Controllers
    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(
        AuthController(
          loginUC: Get.find(),
          registerUC: Get.find(),
          verifyEmailUC: Get.find(),
          resendCodeUC: Get.find(),
          logoutUC: Get.find(),
          enableBiometricUC: Get.find(),
          disableBiometricUC: Get.find(),
          loginWithBiometricUC: Get.find(),
          restoreSessionUC: Get.find(),
        ),
        permanent: true,
      );
    }
    Get.lazyPut(() => SignupController(auth: Get.find()), fenix: true);
  }
}
