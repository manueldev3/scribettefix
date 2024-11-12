import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:form_validator/form_validator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
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

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

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
                          requiredMessage: 'This field is required!',
                        ).build(),
                      ),
                      TextFormField(
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
                        ).email('Insert a valid email!').build(),
                      ),
                      TextFormField(
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
                          requiredMessage: 'This field is required!',
                        ).minLength(8, 'Insert 8 or more chacters.').build(),
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
                          requiredMessage: 'This field is required!',
                        ).minLength(8, 'Insert 8 or more chacters.').add(
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
                  onPressed: () {},
                  icon: const Icon(MingCuteIcons.mgcUser3Fill),
                  label: Text(context.lang!.registerEmail),
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
