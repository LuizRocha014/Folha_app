/// Rotas nomeadas — splash → welcome → login | signup → onboarding → shell.
abstract class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const welcome = '/welcome';
  static const login = '/login';
  static const signup = '/signup';
  static const onboarding = '/onboarding';

  static const shell = '/shell';

  static const transactionDetail = '/transactions/detail';
  static const billDetail = '/bills/detail';

  static const accounts = '/accounts';
  static const creditCards = '/credit-cards';
  static const cardInvoice = '/credit-cards/invoice';
  static const goals = '/goals';
  static const budgets = '/budgets';
  static const notifications = '/notifications';
}
