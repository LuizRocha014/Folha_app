import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/sync/outbox_repository.dart';
import '../../../../../core/sync/sync_manager.dart';
import '../../../../../core/sync/sync_status.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/datasources/goal_local_datasource.dart';
import '../../data/datasources/goal_remote_datasource.dart';
import '../../data/models/goal_model.dart';
import '../../domain/entities/goal_entity.dart';

class GoalsController extends GetxController {
  GoalsController({
    required this.local,
    required this.remote,
    required this.outbox,
    required this.syncManager,
  });

  final GoalLocalDataSource local;
  final GoalRemoteDataSource remote;
  final OutboxRepository outbox;
  final SyncManager syncManager;

  static const _uuid = Uuid();

  final RxList<GoalEntity> items = <GoalEntity>[].obs;
  final RxBool loading = false.obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    refreshList();
  }

  Future<void> refreshList() async {
    loading.value = true;
    try {
      final list = await local.list();
      items.assignAll(list);
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<bool> create({
    required String title,
    required double targetAmount,
    String? description,
    DateTime? targetDate,
    double? monthlyYieldPercent,
    bool isCdb = false,
  }) async {
    try {
      final userId = Get.find<AuthController>().user.value?.id ?? '';
      final goal = GoalModel(
        id: _uuid.v4(),
        userId: userId,
        title: title,
        targetAmount: targetAmount,
        description: description,
        targetDate: targetDate,
        monthlyYieldPercent: monthlyYieldPercent,
        isCdb: isCdb,
        syncStatus: SyncStatus.pendingCreate,
      );
      await local.upsert(goal);
      await outbox.enqueue(
        entity: 'goals',
        entityId: goal.id,
        operation: OutboxOperation.create,
        payload: goal.toApiCreateJson(),
      );
      items.insert(0, goal);
      _pushCreate(goal);
      return true;
    } catch (e) {
      error.value = e.toString();
      return false;
    }
  }

  Future<void> _pushCreate(GoalModel goal) async {
    try {
      await remote.create(goal.toApiCreateJson());
      await syncManager.runFullSync();
      await refreshList();
    } catch (_) {
      // Outbox vai tentar de novo quando online.
    }
  }
}
