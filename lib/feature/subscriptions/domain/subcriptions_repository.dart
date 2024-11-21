import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scribettefix/core/repositories/firebase_repository.dart';

class SubcriptionsRepository extends FirebaseRepository {
  Future<bool> checkSubscription() async {
    String? email = auth.currentUser?.email;

    final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(email)
        .collection(
          'subscriptions',
        )
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      DocumentSnapshot subscriptionDoc = querySnapshot.docs.first;

      DateTime expirationDate =
          (subscriptionDoc['expirationDate'] as Timestamp).toDate();
      bool isSubscribed = subscriptionDoc['isSubscribed'] ?? false;

      if (DateTime.now().isAfter(expirationDate)) {
        await subscriptionDoc.reference.update({
          'isSubscribed': false,
        });
        return false;
      } else {
        return isSubscribed;
      }
    } else {
      return false;
    }
  }
}
