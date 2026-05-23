import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import '../routes/app_routes.dart';
import '../../app/modules/auth/presentation/controllers/auth_controller.dart';
import 'secure_storage_service.dart';

/// Bloqueia o app após [timeout] de inatividade — força o usuário a refazer
/// login (com biometria, se habilitada). Útil pra evitar acesso por terceiros
/// se o device ficar destravado e exposto.
///
/// Uso:
/// ```dart
/// AutoLockService.I.initialize();
/// // E envolva o app:
/// MaterialApp(builder: (ctx, child) => AutoLockGate(child: child!));
/// ```
class AutoLockService {
  AutoLockService._();
  static final AutoLockService I = AutoLockService._();

  Duration timeout = const Duration(minutes: 3);
  Timer? _timer;
  bool _locked = false;

  bool get isLocked => _locked;

  void initialize({Duration? timeout}) {
    if (timeout != null) this.timeout = timeout;
    _reset();
  }

  void registerActivity() {
    if (_locked) return;
    _reset();
  }

  void _reset() {
    _timer?.cancel();
    _timer = Timer(timeout, _lock);
  }

  Future<void> _lock() async {
    if (_locked) return;
    if (!Get.isRegistered<AuthController>()) return;
    final auth = Get.find<AuthController>();
    if (!auth.isAuthenticated) return;

    _locked = true;
    final secure = Get.find<SecureStorageService>();
    if (await secure.isBiometricEnabled()) {
      final ok = await auth.loginWithBiometric();
      _locked = !ok;
      if (!ok) {
        // Biometria falhou — manda pro login com senha.
        Get.offAllNamed(AppRoutes.login);
      }
    } else {
      // Sem biometria — desloga e volta pro welcome.
      await auth.logout();
      Get.offAllNamed(AppRoutes.welcome);
    }
    if (!_locked) _reset();
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Wrapper que captura interações do usuário e reseta o timer de auto-lock.
class AutoLockGate extends StatelessWidget {
  const AutoLockGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => AutoLockService.I.registerActivity(),
      onPointerMove: (_) => AutoLockService.I.registerActivity(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (_) {
          AutoLockService.I.registerActivity();
          return false;
        },
        child: child,
      ),
    );
  }
}

/// Helper para incluir no `WidgetsApp.builder` — registra app-lifecycle.
class AppLifecycleHook extends StatefulWidget {
  const AppLifecycleHook({required this.child, super.key});

  final Widget child;

  @override
  State<AppLifecycleHook> createState() => _AppLifecycleHookState();
}

class _AppLifecycleHookState extends State<AppLifecycleHook>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addObserver(this);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AutoLockService.I.registerActivity();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
