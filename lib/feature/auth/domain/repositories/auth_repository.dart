import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:scribettefix/core/repositories/firebase_repository.dart';

class AuthRepository extends FirebaseRepository {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Stream<User?> stream() {
    return auth.authStateChanges();
  }

  Future<Either<String, User?>> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();

      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );

        final authResult = await _auth.signInWithCredential(credential);

        await _firestore.collection('users').doc(authResult.user?.email).set(
          {
            'name': authResult.user?.displayName,
            'email': authResult.user?.email,
            'UserUid': authResult.user?.uid,
          },
        );

        return Right(authResult.user);
      }
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      log(
        e.code,
        error: e.message,
        stackTrace: e.stackTrace,
      );
      return Left('${e.code}: ${e.message}');
    } on FirebaseException catch (e) {
      log(
        e.code,
        error: e.message,
        stackTrace: e.stackTrace,
      );
      return Left('${e.code}: ${e.message}');
    } catch (error, stackTrace) {
      log(
        error.toString(),
        error: error,
        stackTrace: stackTrace,
      );
      return Left(error.toString());
    }
  }

  Future<Either<String, void>> sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return const Right(null);
    } on FirebaseAuthException catch (error) {
      log(
        error.code,
        error: error.message,
        stackTrace: error.stackTrace,
      );
      return left('${error.code}: ${error.message}');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
