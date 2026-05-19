import 'package:get/get.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/usecases/login_usecase.dart';
import 'domain/usecases/logout_usecase.dart';
import 'domain/usecases/signup_usecase.dart';
import 'presentation/controllers/auth_controller.dart';
import 'presentation/controllers/signup_controller.dart';

/// Binding de auth.
/// - AuthController: permanente (necessário pelo Shell/Profile depois).
/// - SignupController: lazy + fenix (some quando sai do signup, mas reconstrói se voltar).
/// - UseCases/Repository/DataSource: lazy + fenix (alocados sob demanda).
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Data layer (substituir AuthRemoteDataSourceFake por implementação Dio real).
    Get.lazyPut<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceFake(),
      fenix: true,
    );
    Get.lazyPut<AuthRepository>(
      () => AuthRepositoryImpl(remote: Get.find()),
      fenix: true,
    );

    // UseCases
    Get.lazyPut(() => LoginUseCase(Get.find()), fenix: true);
    Get.lazyPut(() => SignupUseCase(Get.find()), fenix: true);
    Get.lazyPut(() => LogoutUseCase(Get.find()), fenix: true);

    // Controllers
    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(
        AuthController(
          loginUC: Get.find(),
          signupUC: Get.find(),
          logoutUC: Get.find(),
        ),
        permanent: true,
      );
    }
    Get.lazyPut(() => SignupController(auth: Get.find()), fenix: true);
  }
}
