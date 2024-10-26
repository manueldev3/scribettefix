import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scribettefix/feature/auth/presentation/pages/auth_loading_page.dart';
import 'package:scribettefix/feature/auth/presentation/pages/login_page.dart';
import 'package:scribettefix/feature/locale/presentation/state/locale_state.dart';
import 'package:scribettefix/firebase_options.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeStateProvider);

    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        splashFactory: NoSplash.splashFactory,
        useMaterial3: true,
        fontFamily: GoogleFonts.montserrat().fontFamily,
        textTheme: GoogleFonts.getTextTheme('Montserrat'),
      ),
      initialRoute: '/auth-loading',
      routes: {
        '/auth-loading': (context) => const AuthLoadingPage(),
        '/login': (context) => const SignInPage(),
        '/register': (context) => Container(),
      },
    );
  }
}
