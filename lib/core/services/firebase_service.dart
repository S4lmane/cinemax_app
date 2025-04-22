import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  // Firebase instances
  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;
  static final FirebaseStorage storage = FirebaseStorage.instance;

  // Initialize Firebase
  static Future<void> initialize() async {
    // Any additional Firebase initialization code can go here
  }

  // User collection reference
  static CollectionReference<Map<String, dynamic>> get usersCollection =>
      firestore.collection('users');

  // Get user document reference
  static DocumentReference<Map<String, dynamic>> getUserDoc(String uid) =>
      usersCollection.doc(uid);

  // Create user profile in Firestore
  static Future<void> createUserProfile({
    required String uid,
    required String email,
    String? displayName,
    String? photoURL,
  }) async {
    await usersCollection.doc(uid).set({
      'email': email,
      'displayName': displayName ?? email.split('@')[0],
      'photoURL': photoURL,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Update user profile
  static Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? photoURL,
  }) async {
    final Map<String, dynamic> data = {};

    if (displayName != null) data['displayName'] = displayName;
    if (photoURL != null) data['photoURL'] = photoURL;
    data['updatedAt'] = FieldValue.serverTimestamp();

    await usersCollection.doc(uid).update(data);
  }
}