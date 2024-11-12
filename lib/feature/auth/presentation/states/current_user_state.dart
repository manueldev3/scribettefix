import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:scribettefix/feature/auth/domain/repositories/auth_repository.dart';

part 'current_user_state.g.dart';

@riverpod
class CurrentUserState extends _$CurrentUserState {
  final repository = AuthRepository();

  Future<User?> _fetch() async {
    return FirebaseAuth.instance.currentUser;
  }

  @override
  FutureOr<User?> build() {
    return _fetch();
  }

  Future<String?> signInWithGoogle() async {
    state = const AsyncLoading();
    final value = await repository.signInWithGoogle();
    User? user;
    final result = value.fold((failure) {
      return failure;
    }, (success) {
      user = success;
      return null;
    });
    state = await AsyncValue.guard(() async {
      return user;
    });
    return result;
  }

  Future<String?> sendResetPassword(String email) async {
    final result = await repository.sendPasswordResetEmail(email);
    return result.fold((failure) {
      return failure;
    }, (_) {
      return null;
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    await repository.signOut();
    state = const AsyncData(null);
  }
}
