import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:form_validator/form_validator.dart';
import 'package:scribettefix/feature/context/domain/extensions/context_extension.dart';
import 'package:scribettefix/feature/ming_cute_icons/presentation/widgets/ming_cute_icons.dart';

/// Sign in Page
/// This is a page for sing authentication
class SignInPage extends ConsumerStatefulWidget {
  /// Sing in page constructor
  const SignInPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  bool _obscurePassword = true;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
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
                  colorFilter: const ColorFilter.mode(
                    Color(
                      0xFF252330,
                    ),
                    BlendMode.srcIn,
                  ),
                ),
                Text(
                  'Scribette',
                  style: context.textTheme.headlineMedium?.merge(
                    const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF252330),
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  context.lang!.slogan,
                  style: context.textTheme.titleMedium?.merge(
                    const TextStyle(
                      color: Color(0xFFA9ACBB),
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
                        cursorColor: const Color(0xFF545A78),
                        decoration: InputDecoration(
                          hintStyle: context.textTheme.titleMedium?.merge(
                            const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF545A78),
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          hintText: context
                              .lang!.emailTextLabel, // Email // EmailTextLabel

                          fillColor: const Color(0xFFE8EFFF),
                          prefixIcon: const Icon(
                            MingCuteIcons.mgcMailFill,
                            color: Color(0xFF545A78),
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
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        cursorColor: const Color(0xFF545A78),
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          hintStyle: context.textTheme.titleMedium?.merge(
                            const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF545A78),
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          hintText: context.lang!
                              .passwordTextLabel, // Email // EmailTextLabel

                          fillColor: const Color(0xFFE8EFFF),
                          prefixIcon: const Icon(
                            MingCuteIcons.mgcMailFill,
                            color: Color(0xFF545A78),
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
                                color: const Color(0xFF545A78),
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
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0XFF252330),
                              textStyle: context.textTheme.labelMedium?.merge(
                                const TextStyle(
                                  color: Color(0xff252330),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            onPressed: () {},
                            child: Text(context.lang!.forgotPassword),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF262D47),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: context.textTheme.titleMedium?.merge(
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {}
                        },
                        icon: const Icon(MingCuteIcons.mgcMailFill),
                        label: Text(
                          context.lang!.signInWithEmailLabel,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF262D47),
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(
                              color: Color(0xFF262D47),
                              width: 2,
                            ),
                          ),
                          textStyle: context.textTheme.titleMedium?.merge(
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        onPressed: () {},
                        icon: const Icon(MingCuteIcons.mgcGoogleFill),
                        label: Text(
                          context.lang!.signInWithEmailGoogleLabel,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFA9ACBB),
                          textStyle: context.textTheme.labelMedium?.merge(
                            const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        onPressed: () {},
                        child: Text(
                          context.lang!.dontAccount,
                        ),
                      )
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
