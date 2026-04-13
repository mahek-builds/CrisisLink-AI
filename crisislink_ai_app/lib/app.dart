import 'package:flutter/material.dart';

import 'screens/launch_screen.dart';
import 'screens/sos_home_page.dart';
import 'theme/app_theme.dart';

class CrisisLinkApp extends StatelessWidget {
  const CrisisLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CrisisLink AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const LaunchScreen(),
      routes: {
        SosHomePage.routeName: (_) => const SosHomePage(),
      },
    );
  }
}
