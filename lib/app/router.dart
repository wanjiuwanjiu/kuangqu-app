import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/session.dart';
import '../features/auth/login_page.dart';
import '../features/home/home_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final s = session.value;
      if (s == null || s is SessionUnknown) return null; // 启动恢复中，保持当前页
      final onLogin = state.matchedLocation == '/login';
      if (s is SessionGuest && !onLogin) return '/login';
      if (s is SessionAuthed && onLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeShell(),
      ),
    ],
  );
});
