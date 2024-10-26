import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scribettefix/feature/auth/presentation/pages/login_page.dart';
import 'package:scribettefix/feature/auth/presentation/states/auth_state.dart';

class AuthLoadingPage extends ConsumerStatefulWidget {
  const AuthLoadingPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AuthLoadingPageState();
}

class _AuthLoadingPageState extends ConsumerState<AuthLoadingPage> {
  @override
  Widget build(BuildContext context) {
    final authChanges = ref.watch(authChangesProvider);
    return authChanges.when(
      data: (User? user) {
        if (user == null) {
          return const SignInPage();
        }
        return Container();
      },
      error: (error, stackTrace) {
        log(
          'error in auth page',
          error: error,
          stackTrace: stackTrace,
        );
        return Container();
      },
      loading: () {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}