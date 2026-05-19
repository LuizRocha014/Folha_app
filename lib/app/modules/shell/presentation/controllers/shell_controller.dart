import 'package:get/get.dart';

/// Controla a tab ativa do shell (Início, Movimentos, Contas, Perfil) e
/// o estado do bottom sheet "Adicionar movimento".
class ShellController extends GetxController {
  /// 0=home, 1=tx, 2=bills, 3=profile (o FAB de Add é tratado fora do índice)
  final RxInt tabIndex = 0.obs;
  final RxBool addSheetOpen = false.obs;

  void goTo(int i) => tabIndex.value = i;

  void openAddSheet() => addSheetOpen.value = true;
  void closeAddSheet() => addSheetOpen.value = false;
}
