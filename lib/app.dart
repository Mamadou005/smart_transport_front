import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'core/constants/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'presentation/widgets/offline_banner.dart';

class SmartTransportApp extends StatelessWidget {
  const SmartTransportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Smart Transport',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRoutes.router,
      // ✅ Builder pour afficher le banner hors-ligne
      builder: (context, child) => Column(
        children: [
          const OfflineBanner(),
          Expanded(child: child!),
        ],
      ),
    );
  }
}