import 'package:get/get.dart';
import '../network/api_client.dart';

/// InitialBinding — injeta serviços globais (ApiClient, etc) na inicialização.
/// Permanecem em memória durante toda a sessão (Get.put).
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<ApiClient>(ApiClient(), permanent: true);
  }
}
