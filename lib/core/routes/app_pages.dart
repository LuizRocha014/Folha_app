import 'package:get/get.dart';
import '../../app/modules/auth/auth_binding.dart';
import '../../app/modules/auth/presentation/pages/login_page.dart';
import '../../app/modules/auth/presentation/pages/signup_page.dart';
import '../../app/modules/auth/presentation/pages/welcome_page.dart';
import '../../app/modules/onboarding/onboarding_binding.dart';
import '../../app/modules/onboarding/presentation/pages/onboarding_page.dart';
import '../../app/modules/shell/shell_binding.dart';
import '../../app/modules/shell/presentation/pages/shell_page.dart';
import '../../app/modules/transactions/presentation/pages/transaction_detail_page.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = AppRoutes.welcome;

  static final routes = <GetPage>[
    GetPage(
      name: AppRoutes.welcome,
      page: () => const WelcomePage(),
      binding: AuthBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.signup,
      page: () => const SignupPage(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingPage(),
      binding: OnboardingBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.shell,
      page: () => const ShellPage(),
      binding: ShellBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.transactionDetail,
      page: () => const TransactionDetailPage(),
      transition: Transition.rightToLeft,
    ),
  ];
}
