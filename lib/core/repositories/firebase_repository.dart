import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

abstract class FirebaseRepository<T> {
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  final storage = FirebaseStorage.instance;
  CollectionReference collection(Collection path) {
    return firestore.collection(path.name);
  }
}

enum Collection {
  users,
  notes,
}
