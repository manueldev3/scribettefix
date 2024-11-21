import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:form_validator/form_validator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scribettefix/feature/auth/presentation/pages/login_page.dart';
import 'package:scribettefix/feature/context/domain/extensions/context_extension.dart';
import 'package:scribettefix/feature/ming_cute_icons/presentation/widgets/ming_cute_icons.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  static String path = '/sign-up';

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  bool _signUpLoading = false;
  bool _obscurePasswords = true;

  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    direction: Axis.vertical,
                    spacing: 8,
                    children: [
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          constraints: BoxConstraints(
                            maxWidth: context.mediaQuery.size.width - 32,
                          ),
                          hintText: context.lang!.usernameLabel,
                          filled: true,
                          fillColor: const Color(0xFFE8EFFF),
                          prefixIcon: const Icon(
                            MingCuteIcons.mgcUser3Fill,
                            color: Color(0xFF545A78),
                          ),
                        ),
                        validator: ValidationBuilder(
                          requiredMessage: context.lang!.requiredMessage,
                        ).build(),
                      ),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          constraints: BoxConstraints(
                            maxWidth: context.mediaQuery.size.width - 32,
                          ),
                          hintText: context.lang!.emailTextLabel,
                          filled: true,
                          fillColor: const Color(0xFFE8EFFF),
                          prefixIcon: Icon(
                            MingCuteIcons.mgcMailFill,
                            color: context.colorScheme.secondary,
                          ),
                        ),
                        validator: ValidationBuilder(
                          requiredMessage: context.lang!.emailSumbit,
                        ).email(context.lang!.validEmailMessage).build(),
                      ),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          constraints: BoxConstraints(
                            maxWidth: context.mediaQuery.size.width - 32,
                          ),
                          hintText: context.lang!.passwordTextLabel,
                          filled: true,
                          fillColor: const Color(0xFFE8EFFF),
                          prefixIcon: Icon(
                            MingCuteIcons.mgcLockFill,
                            color: context.colorScheme.secondary,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePasswords = !_obscurePasswords;
                              });
                            },
                            icon: Icon(
                              _obscurePasswords
                                  ? MingCuteIcons.mgcEyeFill
                                  : MingCuteIcons.mgcEyeCloseFill,
                              color: context.colorScheme.secondary,
                            ),
                          ),
                        ),
                        validator: ValidationBuilder(
                          requiredMessage: context.lang!.requiredMessage,
                        )
                            .minLength(
                              8,
                              context.lang!.passwordLengthMessage(8),
                            )
                            .build(),
                        obscureText: _obscurePasswords,
                      ),
                      TextFormField(
                        decoration: InputDecoration(
                          constraints: BoxConstraints(
                            maxWidth: context.mediaQuery.size.width - 32,
                          ),
                          hintText: context.lang!.confirmPasswordTextLabel,
                          filled: true,
                          fillColor: const Color(0xFFE8EFFF),
                          prefixIcon: Icon(
                            MingCuteIcons.mgcLockFill,
                            color: context.colorScheme.secondary,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePasswords = !_obscurePasswords;
                              });
                            },
                            icon: Icon(
                              _obscurePasswords
                                  ? MingCuteIcons.mgcEyeFill
                                  : MingCuteIcons.mgcEyeCloseFill,
                              color: context.colorScheme.secondary,
                            ),
                          ),
                        ),
                        validator: ValidationBuilder(
                          requiredMessage: context.lang!.requiredMessage,
                        )
                            .minLength(
                                8, context.lang!.passwordLengthMessage(8))
                            .add(
                          (String? value) {
                            if (value != null &&
                                value != _passwordController.text) {
                              return 'This password confirmation is not the same as the password.';
                            }
                            return null;
                          },
                        ).build(),
                        obscureText: _obscurePasswords,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16).copyWith(top: 32),
                child: ElevatedButton.icon(
                  onPressed: _signUpLoading
                      ? () {}
                      : () {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              _signUpLoading = true;
                            });
                            auth
                                .createUserWithEmailAndPassword(
                              email: _emailController.text.trim(),
                              password: _passwordController.text,
                            )
                                .then((userCredential) {
                              userCredential.user!
                                  .sendEmailVerification()
                                  .then((_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: const Color(0xFFF7BD03),
                                      content: Text(
                                          context.lang!.verificationEmailSent),
                                    ),
                                  );
                                }
                              }).catchError((error) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: Colors.red,
                                      content:
                                          Text(context.lang!.anErrorOcurred),
                                    ),
                                  );
                                }
                              });

                              firestore
                                  .collection('users')
                                  .doc(_emailController.text.trim())
                                  .set({
                                'name': _usernameController.text.trim(),
                                'email': _emailController.text.trim(),
                                'UserUid': userCredential.user!.uid,
                                'coins': 0,
                              }).then((_) {
                                if (context.mounted) {
                                  Navigator.of(context)
                                      .pushReplacementNamed("/home");
                                }
                              }).catchError((error) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: Colors.red,
                                      content:
                                          Text(context.lang!.registerFailed),
                                    ),
                                  );
                                }
                              });
                            }).catchError((error) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: Colors.red,
                                    content: Text(context.lang!.registerFailed),
                                  ),
                                );
                              }
                            });
                          } else {
                            setState(() {
                              _signUpLoading = false;
                            });
                          }
                        },
                  icon: _signUpLoading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : const Icon(MingCuteIcons.mgcUser3Fill),
                  label: Text(
                    _signUpLoading
                        ? context.lang!.loading
                        : context.lang!.registerEmail,
                  ),
                ),
              ),
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
                      text: context.lang!.alreadyAccount,
                    ),
                    const WidgetSpan(
                      child: SizedBox(width: 8),
                    ),
                    TextSpan(
                      text: context.lang!.signInLabel,
                      style: context.textTheme.labelMedium?.merge(
                        GoogleFonts.montserrat(
                          color: context.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.of(context).pushReplacementNamed(
                            SignInPage.path,
                          );
                        },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
