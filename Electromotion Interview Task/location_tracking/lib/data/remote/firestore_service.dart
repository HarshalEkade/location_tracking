import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/location_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get userId => _auth.currentUser?.uid;

  Future<void> uploadLocation(LocationModel location) async {
    try {
      final currentUserId = userId;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final locationData = location.toFirestore();
      locationData['userId'] = currentUserId;

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('locations')
          .add(locationData);
    } catch (e) {
      throw Exception('Failed to upload location: $e');
    }
  }

  Future<void> uploadBatchLocations(List<LocationModel> locations) async {
    try {
      final currentUserId = userId;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final batch = _firestore.batch();
      final userRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('locations');

      for (var location in locations) {
        final locationData = location.toFirestore();
        locationData['userId'] = currentUserId;
        batch.set(userRef.doc(), locationData);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to upload batch locations: $e');
    }
  }

  Stream<List<LocationModel>> getLocationsStream() {
    final currentUserId = userId;
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('locations')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LocationModel.fromFirestore(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<void> signInAnonymously() async {
    try {
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}





