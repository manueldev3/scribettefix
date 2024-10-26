import 'package:firebase_auth/firebase_auth.dart';
import 'package:scribettefix/core/repositories/firebase_repository.dart';

class AuthRepository extends FirebaseRepository {
  Stream<User?> stream() {
    return auth.authStateChanges();
  }
}
