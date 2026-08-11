import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khalti_flutter/khalti_flutter.dart';
import 'package:untitled3/app/router/app_router.dart';
import 'package:untitled3/app/theme/app_theme.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return KhaltiScope(
      publicKey: 'test_public_key_5c5fa086bb704a54b1efd924a2acb036',
      // Reuse the same navigator key GoRouter is configured with (see
      // app_router.dart) instead of the one KhaltiScope would otherwise
      // generate for itself, so KhaltiScope.pay()'s internal
      // navigatorState.push/pop targets the app's real (GoRouter-managed)
      // navigator.
      navigatorKey: khaltiNavigatorKey,
      builder: (context, _) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Pooja Pasal',
          theme: AppTheme.lightTheme,
          routerConfig: router,
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('ne', 'NP'),
          ],
          localizationsDelegates: const [
            KhaltiLocalizations.delegate,
          ],
        );
      },
    );
  }
}
