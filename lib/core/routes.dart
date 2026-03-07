import 'package:go_router/go_router.dart';
import '../ui/landing/landing_page.dart';
import '../ui/auth/login_page.dart';
import '../ui/auth/register_page.dart';
import '../ui/dashboard/dashboard_page.dart';
import '../ui/resume_upload/upload_page.dart';
import '../ui/resume_analysis/analysis_page.dart';
import '../ui/resume_history/history_page.dart';
import '../ui/suggestions/suggestions_page.dart';
import '../ui/settings/settings_page.dart';
import '../models/analysis_model.dart';
import '../services/auth_service.dart';

class AppRouter {
  static GoRouter createRouter(AuthService authService) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: authService,
      redirect: (context, state) {
        final isLoggedIn = authService.currentUser != null;
        final isAuthRoute =
            state.matchedLocation == '/login' ||
            state.matchedLocation == '/register' ||
            state.matchedLocation == '/';

        if (authService.isLoading) return null;

        if (!isLoggedIn && !isAuthRoute) {
          return '/login';
        }

        if (isLoggedIn && isAuthRoute) {
          return '/dashboard';
        }

        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (context, state) => const LandingPage()),
        GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
        GoRoute(
          path: '/suggestions',
          builder: (context, state) => const SuggestionsPage(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterPage(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: '/upload',
          builder: (context, state) => const UploadPage(),
        ),
        GoRoute(
          path: '/analysis',
          builder: (context, state) {
            final analysis = state.extra as AnalysisModel?;
            return AnalysisPage(analysis: analysis);
          },
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryPage(),
        ),
      ],
    );
  }
}
