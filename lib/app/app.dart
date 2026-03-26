import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/database/hive_service.dart';
import '../features/history/history_screen.dart';
import '../features/home/home_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/training/training_complete_screen.dart';
import '../features/training/training_list_screen.dart';
import '../features/training/training_session_screen.dart';
import '../shared/theme/app_theme.dart';

class FocusGymApp extends StatefulWidget {
  const FocusGymApp({super.key});

  @override
  State<FocusGymApp> createState() => _FocusGymAppState();
}

class _FocusGymAppState extends State<FocusGymApp> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = HiveService.openBoxes();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
        return MaterialApp.router(
          title: 'FocusGym',
          theme: AppTheme.theme,
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
          locale: const Locale('ja', 'JP'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ja', 'JP'),
            Locale('en', 'US'),
          ],
        );
      },
    );
  }
}

final _router = GoRouter(
  initialLocation: '/home',
  routes: [
    ShellRoute(
      builder: (context, state, child) => _ScaffoldWithNav(child: child),
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(path: '/history', builder: (context, state) => const HistoryScreen()),
        GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      ],
    ),
    GoRoute(path: '/training', builder: (context, state) => const TrainingListScreen()),
    GoRoute(
      path: '/training/complete',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return TrainingCompleteScreen(
          trainingTypeName: extra?['typeName'] as String? ?? '',
          streakDays: extra?['streakDays'] as int? ?? 0,
        );
      },
    ),
    GoRoute(
      path: '/training/:type',
      builder: (context, state) {
        final type = state.pathParameters['type'] ?? 'nearFar';
        return TrainingSessionScreen(trainingType: type);
      },
    ),
  ],
);

class _ScaffoldWithNav extends StatelessWidget {
  final Widget child;
  const _ScaffoldWithNav({required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/history')) return 1;
    if (location.startsWith('/settings')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex(context),
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/home');
            case 1:
              context.go('/history');
            case 2:
              context.go('/settings');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: '履歴'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: '設定'),
        ],
      ),
    );
  }
}
