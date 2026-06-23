import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/pin_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/transfers/screens/transfer_wizard_screen.dart';
import '../../features/transfers/screens/transfer_history_screen.dart';
import '../../features/transfers/screens/transfer_detail_screen.dart';
import '../../features/beneficiaries/screens/beneficiaries_screen.dart';
import '../../features/beneficiaries/screens/add_beneficiary_screen.dart';
import '../../features/cards/screens/cards_screen.dart';
import '../../features/kyc/screens/kyc_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../shell/main_shell.dart';

final _storage = const FlutterSecureStorage();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final token = await _storage.read(key: 'auth_token');
      final isLoggedIn = token != null;
      final isOnAuth = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register') ||
          state.matchedLocation.startsWith('/otp');

      if (!isLoggedIn && !isOnAuth) return '/login';
      if (isLoggedIn && state.matchedLocation == '/login') return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login',    builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
      GoRoute(path: '/otp',      builder: (c, s) => OtpScreen(phone: s.extra as String? ?? '')),
      GoRoute(path: '/pin',      builder: (c, s) => const PinScreen()),

      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (c, s) => const DashboardScreen()),
          GoRoute(
            path: '/transfers',
            builder: (c, s) => const TransferHistoryScreen(),
            routes: [
              GoRoute(path: 'nouveau', builder: (c, s) => const TransferWizardScreen()),
              GoRoute(path: ':uuid',   builder: (c, s) => TransferDetailScreen(uuid: s.pathParameters['uuid']!)),
            ],
          ),
          GoRoute(
            path: '/beneficiaries',
            builder: (c, s) => const BeneficiariesScreen(),
            routes: [
              GoRoute(path: 'nouveau', builder: (c, s) => const AddBeneficiaryScreen()),
            ],
          ),
          GoRoute(path: '/cartes',        builder: (c, s) => const CardsScreen()),
          GoRoute(path: '/kyc',           builder: (c, s) => const KycScreen()),
          GoRoute(path: '/profil',        builder: (c, s) => const ProfileScreen()),
          GoRoute(path: '/notifications', builder: (c, s) => const NotificationsScreen()),
        ],
      ),
    ],
  );
});
