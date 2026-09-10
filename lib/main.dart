import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/providers.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'features/splash/splash_page.dart';
import 'l10n/gen/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Month and weekday names for every supported locale, not just the device's.
  await initializeDateFormatting();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const ProviderScope(child: RaInsightsApp()));
}

class RaInsightsApp extends ConsumerWidget {
  const RaInsightsApp({super.key});

  static const _delegates = <LocalizationsDelegate<Object>>[
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final locale = ref.watch(localeProvider);
    // Only started once the session is known, so a signed-out launch does not
    // wait on a dashboard it will never show.
    final booting = session.isLoading || ref.watch(bootProvider).isLoading;

    // The router is only built once the stored credentials have been read;
    // otherwise the first frame would bounce through onboarding.
    if (booting || locale.isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildDarkTheme(),
        locale: locale.valueOrNull,
        localizationsDelegates: _delegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SplashScreen(),
      );
    }

    return MaterialApp.router(
      title: 'RA Insights',
      debugShowCheckedModeBanner: false,
      theme: buildDarkTheme(),
      // null falls back to the device language, then to the template locale.
      locale: locale.valueOrNull,
      localizationsDelegates: _delegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
