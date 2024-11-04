import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:form_validator/form_validator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:scribettefix/feature/auth/presentation/pages/login_page.dart';
import 'package:scribettefix/feature/auth/presentation/states/current_user_state.dart';
import 'package:scribettefix/feature/context/domain/extensions/context_extension.dart';
import 'package:scribettefix/feature/ming_cute_icons/presentation/widgets/ming_cute_icons.dart';

class ForgotPasswordArguments {
  final String fromPath;

  ForgotPasswordArguments({
    required this.fromPath,
  });
}

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  static String path = '/forgot-password';

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  bool _sendingEmail = false;

  final GoogleSignIn googleSignIn = GoogleSignIn();

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as ForgotPasswordArguments;
    final authNotifier = ref.read(currentUserStateProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            if (args.fromPath == SignInPage.path) {
              Navigator.of(context).pushReplacementNamed(SignInPage.path);
            } else {
              Navigator.of(context).pushReplacementNamed("/home");
            }
          },
          icon: Icon(
            MingCuteIcons.mgcLeftFill,
            color: context.colorScheme.onSurface,
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
            Text(
              context.lang!
                  .resetEmail, // "Please enter your email address below to receive a link to reset your password." // resetEmail
              style: const TextStyle(
                color: Color(0xFFA9ACBB),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: TextFormField(
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
                  requiredMessage: context.lang!.emailSumbit,
                )
                    .email(
                      'Debe ingresar un correo electrónico válido',
                    )
                    .build(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sendingEmail
                    ? () {}
                    : () async {
                        setState(() {
                          _sendingEmail = true;
                        });
                        if (_formKey.currentState!.validate()) {
                          final failure = await authNotifier.sendResetPassword(
                            _emailController.text.trim(),
                          );

                          if (failure != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: context.colorScheme.primary,
                                content: Text(failure),
                              ),
                            );
                          } else if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: context.colorScheme.primary,
                                content: Text(
                                  context.lang!.emailSentReset,
                                ),
                              ),
                            );
                            if (args.fromPath == SignInPage.path &&
                                context.mounted) {
                              Navigator.of(context).pushReplacementNamed(
                                SignInPage.path,
                              );
                            } else if (context.mounted) {
                              Navigator.of(context).pushReplacementNamed(
                                "/home",
                              );
                            }
                          }
                        }
                        setState(() {
                          _sendingEmail = false;
                        });
                      },
                icon: _sendingEmail
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        MingCuteIcons.mgcMailFill,
                        color: Colors.white,
                      ),
                label: Text(
                  _sendingEmail ? 'Cargando...' : context.lang!.sendResetLink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
