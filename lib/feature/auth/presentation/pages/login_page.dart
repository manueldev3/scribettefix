import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:form_validator/form_validator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scribettefix/feature/auth/presentation/pages/forgot_password_page.dart';
import 'package:scribettefix/feature/auth/presentation/pages/sign_up_page.dart';
import 'package:scribettefix/feature/auth/presentation/states/current_user_state.dart';
import 'package:scribettefix/feature/context/domain/extensions/context_extension.dart';
import 'package:scribettefix/feature/home/presentation/pages/home_page.dart';
import 'package:scribettefix/feature/ming_cute_icons/presentation/widgets/ming_cute_icons.dart';

/// Sign in Page
/// This is a page for sing authentication
class SignInPage extends ConsumerStatefulWidget {
  /// Sing in page constructor
  const SignInPage({super.key});

  static String path = '/login';

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  bool _loading = false;
  bool _signinGoogle = false;
  bool _obscurePassword = true;

  final auth = FirebaseAuth.instance;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final currentUserNotifier = ref.read(
      currentUserStateProvider.notifier,
    );
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  "assets/logo.svg",
                  height: 120,
                  colorFilter: ColorFilter.mode(
                    context.colorScheme.primary,
                    BlendMode.srcIn,
                  ),
                ),
                Text(
                  'Scribette,',
                  style: GoogleFonts.montserrat(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: context.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  context.lang!.slogan,
                  style: context.textTheme.titleMedium?.merge(
                    TextStyle(
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        cursorColor: context.colorScheme.secondary,
                        decoration: InputDecoration(
                          hintText: context.lang!.emailTextLabel,
                          prefixIcon: Icon(
                            MingCuteIcons.mgcMailFill,
                            color: context.colorScheme.secondary,
                          ),
                        ),
                        validator: ValidationBuilder(
                          requiredMessage: 'Este campo es obligatorio',
                        )
                            .email(
                              'Debe ingresar un correo electrónico válido',
                            )
                            .build(),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        cursorColor: context.colorScheme.secondary,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          hintText: context.lang!.passwordTextLabel,
                          prefixIcon: Icon(
                            MingCuteIcons.mgcLockFill,
                            color: context.colorScheme.secondary,
                          ),
                          suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? MingCuteIcons.mgcEyeFill
                                    : MingCuteIcons.mgcEyeCloseFill,
                                color: context.colorScheme.secondary,
                              )),
                        ),
                        validator: ValidationBuilder(
                          requiredMessage: 'Este campo es obligatorio',
                        ).build(),
                        obscureText: _obscurePassword,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed(
                                ForgotPasswordPage.path,
                                arguments: ForgotPasswordArguments(
                                  fromPath: SignInPage.path,
                                ),
                              );
                            },
                            child: Text(context.lang!.forgotPassword),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loading
                            ? () {}
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  setState(() {
                                    _loading = true;
                                  });

                                  auth
                                      .signInWithEmailAndPassword(
                                    email: _emailController.text.trim(),
                                    password: _passwordController.text,
                                  )
                                      .then((UserCredential
                                          userCredential) async {
                                    if (userCredential.user != null) {
                                      if (context.mounted) {
                                        Navigator.of(context)
                                            .pushReplacementNamed(
                                          HomePage.path,
                                        );
                                      }
                                    } else {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            backgroundColor:
                                                const Color(0xFF262D47),
                                            content: Text(
                                              context.lang!.errorSign,
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  });
                                }
                              },
                        icon: _loading
                            ? const Center(
                                child: CircularProgressIndicator(),
                              )
                            : const Icon(MingCuteIcons.mgcMailFill),
                        label: Text(
                          _loading
                              ? context.lang!.loading
                              : context.lang!.signInWithEmailLabel,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: context.colorScheme.primary,
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: context.colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          textStyle: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: _signinGoogle
                            ? () {}
                            : () async {
                                setState(() {
                                  _signinGoogle = true;
                                });
                                final result = await currentUserNotifier
                                    .signInWithGoogle();
                                if (result != null && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(result),
                                    ),
                                  );
                                }
                                setState(() {
                                  _signinGoogle = false;
                                });
                              },
                        icon: const Icon(MingCuteIcons.mgcGoogleFill),
                        label: Text(
                          _signinGoogle
                              ? context.lang!.loading
                              : context.lang!.signInWithEmailGoogleLabel,
                        ),
                      ),
                      const SizedBox(height: 16),
                      RichText(
                        text: TextSpan(
                          style: context.textTheme.labelMedium?.merge(
                            GoogleFonts.montserrat(
                              color: context.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          children: [
                            TextSpan(
                              text: context.lang!.dontAccount,
                            ),
                            const WidgetSpan(
                              child: SizedBox(width: 8),
                            ),
                            TextSpan(
                              text: context.lang!.registerLabelName,
                              style: context.textTheme.labelMedium?.merge(
                                GoogleFonts.montserrat(
                                  color: context.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.of(context).pushReplacementNamed(
                                    SignUpPage.path,
                                  );
                                },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
