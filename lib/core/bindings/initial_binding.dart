import 'package:get/get.dart';
import '../network/connectivity_service.dart';
import '../network/folha_http_client.dart';
import '../security/biometric_service.dart';
import '../security/device_info_service.dart';
import '../security/secure_storage_service.dart';

/// Registra serviços globais. Tudo aqui é `permanent: true` — sobrevive
/// a `Get.offAll(...)` e fica disponível em qualquer módulo.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<SecureStorageService>(SecureStorageService(), permanent: true);
    Get.put<BiometricService>(BiometricService(), permanent: true);
    Get.put<DeviceInfoService>(
      DeviceInfoService(Get.find<SecureStorageService>()),
      permanent: true,
    );
    Get.put<ConnectivityService>(ConnectivityService(), permanent: true);

    final secureStorage = Get.find<SecureStorageService>();
    Get.put<FolhaHttpClient>(
      FolhaHttpClient(
        secureStorage: secureStorage,
        deviceInfo: Get.find<DeviceInfoService>(),
        onUnauthorized: () async => secureStorage.clearSession(),
      ),
      permanent: true,
    );
  }
}
