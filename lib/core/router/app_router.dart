import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/apply/apply_screen.dart';
import '../../features/applications/applications_screen.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/auth/password_reset_screen.dart';
import '../../features/company/company_profile_screen.dart';
import '../../features/employer/employer_dashboard_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/job_details/job_details_screen.dart';
import '../../features/messages/messages_screen.dart';
import '../../features/messages/message_thread_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/saved/saved_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/shell/main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavigatorKey = GlobalKey<NavigatorState>();
final _savedNavigatorKey = GlobalKey<NavigatorState>();
final _applicationsNavigatorKey = GlobalKey<NavigatorState>();
final _notificationsNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => AuthScreen(
        nextLocation: state.uri.queryParameters['next'],
        startWithSignIn: state.uri.queryParameters['mode'] == 'signin',
      ),
    ),
    GoRoute(
      path: '/reset',
      builder: (context, state) => const PasswordResetScreen(),
    ),
    GoRoute(
      path: '/employer',
      builder: (context, state) => const EmployerDashboardScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/search',
      builder: (context, state) => const SearchScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          navigatorKey: _homeNavigatorKey,
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _savedNavigatorKey,
          routes: [
            GoRoute(
              path: '/saved',
              builder: (context, state) => const SavedScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _applicationsNavigatorKey,
          routes: [
            GoRoute(
              path: '/applications',
              builder: (context, state) => const ApplicationsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _notificationsNavigatorKey,
          routes: [
            GoRoute(
              path: '/notifications',
              builder: (context, state) => const NotificationsScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/job/:id',
      builder: (context, state) =>
          JobDetailsScreen(jobId: state.pathParameters['id']!),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/company/:id',
      builder: (context, state) =>
          CompanyProfileScreen(companyId: state.pathParameters['id']!),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/apply/:id',
      builder: (context, state) =>
          ApplyScreen(jobId: state.pathParameters['id']!),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/messages',
      builder: (context, state) => const MessagesScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/messages/:id',
      builder: (context, state) =>
          MessageThreadScreen(messageId: state.pathParameters['id']!),
    ),
  ],
);
