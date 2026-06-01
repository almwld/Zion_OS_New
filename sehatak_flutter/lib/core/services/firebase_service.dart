import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  late final FirebaseAuth auth;
  late final FirebaseFirestore firestore;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    auth = FirebaseAuth.instance;
    firestore = FirebaseFirestore.instance;
    auth.setLanguageCode('ar');
    _initialized = true;
  }

  User? get currentUser => auth.currentUser;
  Stream<User?> get authState => auth.authStateChanges();
  bool get isLoggedIn => auth.currentUser != null;

  // Collections
  CollectionReference get usersCol => firestore.collection('users');
  CollectionReference get doctorsCol => firestore.collection('doctors');
  CollectionReference get appointmentsCol => firestore.collection('appointments');
  
  DocumentReference userDoc(String uid) => usersCol.doc(uid);
}
