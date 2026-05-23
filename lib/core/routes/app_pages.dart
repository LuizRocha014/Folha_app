import 'package:get/get.dart';
import '../../app/modules/accounts/accounts_binding.dart';
import '../../app/modules/accounts/presentation/pages/accounts_page.dart';
import '../../app/modules/auth/auth_binding.dart';
import '../../app/modules/auth/presentation/pages/login_page.dart';
import '../../app/modules/auth/presentation/pages/signup_page.dart';
import '../../app/modules/auth/presentation/pages/welcome_page.dart';
import '../../app/modules/budgets/presentation/pages/budgets_page.dart';
import '../../app/modules/credit_cards/credit_cards_binding.dart';
import '../../app/modules/credit_cards/presentation/pages/credit_cards_page.dart';
import '../../app/modules/goals/goals_binding.dart';
import '../../app/modules/goals/presentation/pages/goals_page.dart';
import '../../app/modules/notifications/notifications_binding.dart';
import '../../app/modules/notifications/presentation/pages/notifications_page.dart';
import '../../app/modules/onboarding/onboarding_binding.dart';
import '../../app/modules/onboarding/presentation/pages/onboarding_page.dart';
import '../../app/modules/shell/shell_binding.dart';
import '../../app/modules/shell/presentation/pages/shell_page.dart';
import '../../app/modules/splash/splash_page.dart';
import '../../app/modules/transactions/presentation/pages/transaction_detail_page.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = AppRoutes.splash;

  static final routes = <GetPage>[
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashPage(),
      transition: Transition.fadeIn,
    ),
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
    GetPage(
      name: AppRoutes.accounts,
      page: () => const AccountsPage(),
      binding: AccountsBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.creditCards,
      page: () => const CreditCardsPage(),
      binding: CreditCardsBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.goals,
      page: () => const GoalsPage(),
      binding: GoalsBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.budgets,
      page: () => const BudgetsPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsPage(),
      binding: NotificationsBinding(),
      transition: Transition.rightToLeft,
    ),
  ];
}
