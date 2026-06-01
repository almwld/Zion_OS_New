import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class FirebaseAuthService {
  final FirebaseService _fb = FirebaseService();

  // تسجيل الدخول بالإيميل
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    return await _fb.auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // إنشاء حساب جديد
  Future<UserCredential?> createAccount(String email, String password, String name, String phone) async {
    final userCred = await _fb.auth.createUserWithEmailAndPassword(email: email, password: password);
    await _fb.userDoc(userCred.user!.uid).set({
      'id': userCred.user!.uid,
      'email': email,
      'phone': phone,
      'fullName': name,
      'role': 'patient',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return userCred;
  }

  // تسجيل الدخول بالهاتف - إرسال OTP
  Future<void> sendPhoneOTP(String phone, {
    required Function(String) onCodeSent,
    required Function(String) onError,
    required Function(PhoneAuthCredential) onAutoVerified,
  }) async {
    await _fb.auth.verifyPhoneNumber(
      phoneNumber: '+967$phone',
      verificationCompleted: onAutoVerified,
      verificationFailed: (e) => onError(e.message ?? 'خطأ'),
      codeSent: (id, token) => onCodeSent(id),
      codeAutoRetrievalTimeout: (id) {},
    );
  }

  // تأكيد OTP
  Future<UserCredential?> verifyOTP(String verificationId, String otp) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );
    return await _fb.auth.signInWithCredential(credential);
  }

  // تسجيل الخروج
  Future<void> signOut() async => await _fb.auth.signOut();

  // إعادة تعيين كلمة المرور
  Future<void> resetPassword(String email) async {
    await _fb.auth.sendPasswordResetEmail(email: email);
  }
}
