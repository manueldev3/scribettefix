import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scribettefix/core/repositories/firebase_repository.dart';

class UserRepository extends FirebaseRepository {
  Future<void> uploadAvatar(File image) async {
    try {
      debugPrint('image: ${image.path}');
      final email = auth.currentUser?.email;
      debugPrint('email $email');
      if (email != null) {
        final storageRef = storage.ref().child(
              "profile_images/$email.jpg",
            );
        await storageRef.putFile(image);
        String downloadURL = await storageRef.getDownloadURL();
        debugPrint('downloadURL: $downloadURL');
        await collection(Collection.users).doc(email).update({
          'profileImageUrl': downloadURL,
        });
      }
    } catch (e, s) {
      debugPrint('$e: $s');
    }
  }

  Future<File?> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final File file = File(pickedFile.path);
      await uploadAvatar(file);
      return file;
    }
    return null;
  }
}
