import 'dart:io';

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:scribettefix/feature/settings/domain/entities/user_entity.dart';
import 'package:scribettefix/feature/settings/domain/repositories/user_repository.dart';

part 'user_state.g.dart';

@riverpod
class UserState extends _$UserState {
  final repository = UserRepository();
  @override
  Stream<UserEntity?> build() {
    final email = repository.auth.currentUser?.email;
    debugPrint(email);
    if (email != null) {
      debugPrint(email);
      final snapshot = repository.firestore
          .collection(
            'users',
          )
          .doc(email)
          .snapshots();
      return snapshot.map((event) {
        debugPrint(event.data().toString());
        return UserEntity.fromJson(event.data()!);
      });
    }
    return Stream.value(null);
  }

  Future<File?> pickAvatar() async {
    return repository.pickImage();
  }
}
