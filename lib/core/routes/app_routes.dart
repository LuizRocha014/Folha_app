/// Rotas nomeadas — espelha o "phase navigator" do protótipo:
/// welcome → login | signup → onboarding → shell (tabs)
abstract class AppRoutes {
  AppRoutes._();

  static const welcome = '/welcome';
  static const login = '/login';
  static const signup = '/signup';
  static const onboarding = '/onboarding';

  static const shell = '/shell';

  static const transactionDetail = '/transactions/detail';
}
