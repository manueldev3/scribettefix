import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scribettefix/feature/auth/presentation/pages/auth_loading_page.dart';
import 'package:scribettefix/feature/auth/presentation/pages/forgot_password_page.dart';
import 'package:scribettefix/feature/auth/presentation/pages/login_page.dart';
import 'package:scribettefix/feature/auth/presentation/pages/sign_up_page.dart';
import 'package:scribettefix/feature/home/presentation/pages/home_page.dart';
import 'package:scribettefix/feature/locale/presentation/state/locale_state.dart';
import 'package:scribettefix/feature/settings/presentation/pages/settings_page.dart';
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

    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF262D47),
      onPrimary: Colors.white,
      secondary: Color(0xFF545A78),
      onSecondary: Colors.white,
      error: Colors.red,
      onError: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFFA9ACBB),
    );

    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        splashFactory: NoSplash.splashFactory,
        useMaterial3: true,
        colorScheme: colorScheme,
        fontFamily: GoogleFonts.montserrat().fontFamily,
        textTheme: GoogleFonts.montserratTextTheme(),
        appBarTheme: AppBarTheme(
          titleTextStyle: GoogleFonts.montserrat(
            color: colorScheme.primary,
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
        dropdownMenuTheme: const DropdownMenuThemeData(
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Color(0xFFE8EFFF),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          hintStyle: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: colorScheme.secondary,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: const Color(0xFFE8EFFF),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.primary,
            textStyle: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      initialRoute: AuthLoadingPage.path,
      routes: <String, WidgetBuilder>{
        AuthLoadingPage.path: (context) => const AuthLoadingPage(),
        SignInPage.path: (context) => const SignInPage(),
        ForgotPasswordPage.path: (context) => const ForgotPasswordPage(),
        SignUpPage.path: (context) => const SignUpPage(),
        HomePage.path: (context) => const HomePage(),
        SettingsPage.path: (context) => const SettingsPage(),
      },
    );
  }
}
