import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/providers.dart';
import '../screens/home_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/paywall_screen.dart';
import '../screens/settings_screen.dart';

final Provider<GoRouter> routerProvider = Provider<GoRouter>((Ref ref) {
  final SharedPreferences prefs = ref.watch(sharedPrefsProvider);
  final bool seen = prefs.getBool('onboarding_done') ?? false;
  return GoRouter(
    initialLocation: seen ? '/home' : '/onboarding',
    routes: <RouteBase>[
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/paywall', builder: (_, __) => const PaywallScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    ],
  );
});
