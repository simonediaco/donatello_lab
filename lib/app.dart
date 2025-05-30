import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class DonatelloLabApp extends StatelessWidget {
  const DonatelloLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Donatello Lab',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('it'),
      ],
    );
  }
}