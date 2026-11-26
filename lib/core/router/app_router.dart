import 'package:go_router/go_router.dart';

import '../../features/home/presentation/home_screen.dart';
import '../../features/reports/presentation/monthly_report_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/reports',
      builder: (context, state) => const MonthlyReportScreen(),
    ),
  ],
);
