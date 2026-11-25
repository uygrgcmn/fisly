import 'package:material_ui/material_ui.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class FislyApp extends StatelessWidget {
  const FislyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Fisly',
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
