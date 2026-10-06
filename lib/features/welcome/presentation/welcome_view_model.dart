import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';

final welcomeViewModelProvider = Provider<WelcomeViewModel>(
  (ref) => WelcomeViewModel(ref.watch(routerProvider)),
);

class WelcomeViewModel {
  const WelcomeViewModel(this._router);

  final GoRouter _router;

  void openLogin() => _router.goNamed('login');

  void openRegister() => _router.goNamed('register');
}
