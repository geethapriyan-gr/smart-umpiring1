import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../../providers/video_provider.dart';
import '../../screens/splash_screen.dart';
import '../../theme/app_theme.dart';

class SmartUmpireApp extends StatelessWidget {
  const SmartUmpireApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => VideoProvider())],
      child: MaterialApp(
        title: 'Smart Cricket Umpiring',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''),
          Locale('es', ''),
          Locale('hi', ''),
          Locale('ar', ''),
          Locale('zh', ''),
        ],
        home: const SplashScreen(),
      ),
    );
  }
}
