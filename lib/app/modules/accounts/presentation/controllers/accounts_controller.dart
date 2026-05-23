import 'package:get/get.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/repositories/account_repository.dart';

class AccountsController extends GetxController {
  AccountsController({required this.repository});

  final AccountRepository repository;

  final RxList<AccountEntity> items = <AccountEntity>[].obs;
  final RxBool loading = false.obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    refreshList();
  }

  Future<void> refreshList() async {
    loading.value = true;
    final res = await repository.list();
    res.fold((f) => error.value = f.message, (l) => items.assignAll(l));
    loading.value = false;
  }

  Future<bool> create({
    required String name,
    required String kind,
    String? institution,
    double initialBalance = 0,
  }) async {
    final res = await repository.create(
      name: name,
      kind: kind,
      institution: institution,
      initialBalance: initialBalance,
    );
    return res.fold(
      (f) {
        error.value = f.message;
        return false;
      },
      (a) {
        items.insert(0, a);
        return true;
      },
    );
  }

  Future<void> archive(String id) async {
    final res = await repository.archive(id);
    res.fold(
      (f) => error.value = f.message,
      (_) => items.removeWhere((a) => a.id == id),
    );
  }
}
