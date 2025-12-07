import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/providers/settings_provider.dart';

/// Global navigator key for closing popups from anywhere
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Helper to close all open popups (BottomSheets, Dialogs, etc.)
void closeAllPopups() {
  final navigator = rootNavigatorKey.currentState;
  if (navigator == null) return;

  // Pop all popup routes (BottomSheets, Dialogs, Menus)
  navigator.popUntil((route) => route is! PopupRoute);
}

class SawnApp extends ConsumerWidget {
  const SawnApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'صَوْن',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      
      // Localization
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      // Router
      routerConfig: router,
    );
  }
}
