import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  late final FirebaseAuth auth;
  late final FirebaseFirestore firestore;

  Future<void> initialize() async {
    auth = FirebaseAuth.instance;
    firestore = FirebaseFirestore.instance;
    auth.setLanguageCode('ar');
  }

  User? get currentUser => auth.currentUser;
  Stream<User?> get authState => auth.authStateChanges();
  bool get isLoggedIn => auth.currentUser != null;

  CollectionReference get usersCol => firestore.collection('users');
  CollectionReference get doctorsCol => firestore.collection('doctors');
  CollectionReference get appointmentsCol => firestore.collection('appointments');
  DocumentReference userDoc(String uid) => usersCol.doc(uid);
}
