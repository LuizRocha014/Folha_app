import 'package:get/get.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../domain/entities/credit_card_entity.dart';
import '../../domain/usecases/credit_card_usecases.dart';

class CreditCardsController extends GetxController {
  CreditCardsController({
    required this.listUC,
    required this.createUC,
    required this.archiveUC,
  });

  final ListCreditCardsUseCase listUC;
  final CreateCreditCardUseCase createUC;
  final ArchiveCreditCardUseCase archiveUC;

  final RxList<CreditCardEntity> items = <CreditCardEntity>[].obs;
  final RxBool loading = false.obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    refreshList();
  }

  Future<void> refreshList() async {
    loading.value = true;
    final r = await listUC(const NoParams());
    r.fold((f) => error.value = f.message, items.assignAll);
    loading.value = false;
  }

  Future<bool> create({
    required String name,
    required String brand,
    required double creditLimit,
    required int closingDay,
    required int dueDay,
    String? lastFour,
    String? accountId,
  }) async {
    final r = await createUC(CreateCreditCardParams(
      name: name,
      brand: brand,
      creditLimit: creditLimit,
      closingDay: closingDay,
      dueDay: dueDay,
      lastFour: lastFour,
      accountId: accountId,
    ));
    return r.fold(
      (f) {
        error.value = f.message;
        return false;
      },
      (card) {
        items.insert(0, card);
        return true;
      },
    );
  }

  Future<void> archive(String id) async {
    final r = await archiveUC(id);
    r.fold(
      (f) => error.value = f.message,
      (_) => items.removeWhere((c) => c.id == id),
    );
  }

  double get totalLimit =>
      items.fold<double>(0, (sum, c) => sum + c.creditLimit);
}
