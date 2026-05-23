import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/bindings/initial_binding.dart';
import 'core/config/app_config.dart';
import 'core/routes/app_pages.dart';
import 'core/security/auto_lock_service.dart';
import 'core/theme/folha_colors.dart';
import 'core/theme/folha_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();
  await initializeDateFormatting('pt_BR');

  AutoLockService.I.initialize(timeout: const Duration(minutes: 3));

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: FolhaColors.paper100,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const FolhaApp());
}

class FolhaApp extends StatelessWidget {
  const FolhaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Folha',
      debugShowCheckedModeBanner: false,
      theme: FolhaTheme.light(),
      initialBinding: InitialBinding(),
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      locale: const Locale('pt', 'BR'),
      fallbackLocale: const Locale('pt', 'BR'),
      builder: (context, child) => AppLifecycleHook(
        child: AutoLockGate(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
