import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/services/firebase_service.dart';
import '../../../data/models/user_models/user_model.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
}
class AppStarted extends AuthEvent { @override List<Object?> get props => []; }
class LoginWithEmail extends AuthEvent {
  final String email, password;
  const LoginWithEmail({required this.email, required this.password});
  @override List<Object?> get props => [email, password];
}
class LoginWithGoogle extends AuthEvent { @override List<Object?> get props => []; }
class LoginWithPhone extends AuthEvent {
  final String phone;
  const LoginWithPhone(this.phone);
  @override List<Object?> get props => [phone];
}
class VerifyPhoneOTP extends AuthEvent {
  final String verificationId, otp;
  const VerifyPhoneOTP({required this.verificationId, required this.otp});
  @override List<Object?> get props => [verificationId, otp];
}
class RegisterWithEmail extends AuthEvent {
  final String name, email, phone, password;
  const RegisterWithEmail({required this.name, required this.email, required this.phone, required this.password});
  @override List<Object?> get props => [name, email, phone, password];
}
class ResetPassword extends AuthEvent {
  final String email;
  const ResetPassword(this.email);
  @override List<Object?> get props => [email];
}
class ResendOTP extends AuthEvent {
  final String phone;
  const ResendOTP(this.phone);
  @override List<Object?> get props => [phone];
}
class TickTimer extends AuthEvent { @override List<Object?> get props => []; }
class Logout extends AuthEvent { @override List<Object?> get props => []; }
class EnterAsGuest extends AuthEvent { @override List<Object?> get props => []; }

abstract class AuthState extends Equatable {
  const AuthState();
}
class AuthInitial extends AuthState { @override List<Object?> get props => []; }
class AuthLoading extends AuthState { @override List<Object?> get props => []; }
class AuthCodeSent extends AuthState {
  final String verificationId;
  final int resendAfter; // ثواني
  const AuthCodeSent({required this.verificationId, this.resendAfter = 30});
  @override List<Object?> get props => [verificationId, resendAfter];
}
class Authenticated extends AuthState {
  final UserModel user;
  const Authenticated(this.user);
  @override List<Object?> get props => [user];
}
class Unauthenticated extends AuthState { @override List<Object?> get props => []; }
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override List<Object?> get props => [message];
}
class PasswordResetSent extends AuthState { @override List<Object?> get props => []; }

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseService _fb = FirebaseService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  Timer? _timer;
  int _secondsLeft = 30;

  AuthBloc() : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginWithEmail>(_onLogin);
    on<LoginWithGoogle>(_onGoogleLogin);
    on<LoginWithPhone>(_onLoginPhone);
    on<VerifyPhoneOTP>(_onVerifyOTP);
    on<RegisterWithEmail>(_onRegister);
    on<ResetPassword>(_onResetPassword);
    on<ResendOTP>(_onResendOTP);
    on<TickTimer>(_onTick);
    on<EnterAsGuest>(_onGuest);
    on<Logout>(_onLogout);
  }

  void _startTimer() {
    _secondsLeft = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => add(TickTimer()));
  }

  void _onTick(TickTimer e, Emitter<AuthState> emit) {
    _secondsLeft--;
    if (_secondsLeft <= 0) {
      _timer?.cancel();
      _secondsLeft = 0;
    }
    // تحديث الحالة مع عدد الثواني المتبقية
    if (state is AuthCodeSent) {
      final s = state as AuthCodeSent;
      emit(AuthCodeSent(verificationId: s.verificationId, resendAfter: _secondsLeft));
    }
  }

  void _onAppStarted(AppStarted e, Emitter<AuthState> emit) {
    if (_fb.auth.currentUser != null) {
      emit(Authenticated(UserModel(id: _fb.auth.currentUser!.uid, email: _fb.auth.currentUser!.email)));
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLogin(LoginWithEmail e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _fb.auth.signInWithEmailAndPassword(email: e.email.trim(), password: e.password);
      emit(Authenticated(UserModel(id: _fb.auth.currentUser!.uid, email: e.email)));
    } on FirebaseAuthException catch (ex) {
      emit(AuthError(_msg(ex.code)));
    } catch (ex) {
      emit(AuthError('تأكد من اتصال الإنترنت'));
    }
  }

  Future<void> _onGoogleLogin(LoginWithGoogle e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) { emit(Unauthenticated()); return; }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
      await _fb.auth.signInWithCredential(credential);
      emit(Authenticated(UserModel(id: _fb.auth.currentUser!.uid, email: _fb.auth.currentUser!.email)));
    } catch (ex) {
      emit(AuthError('فشل Google'));
    }
  }

  Future<void> _onLoginPhone(LoginWithPhone e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _fb.auth.verifyPhoneNumber(
        phoneNumber: '+967${e.phone}',
        verificationCompleted: (cred) async { await _fb.auth.signInWithCredential(cred); },
        verificationFailed: (ex) => emit(AuthError(ex.message ?? 'خطأ')),
        codeSent: (id, token) {
          _startTimer();
          emit(AuthCodeSent(verificationId: id, resendAfter: 30));
        },
        codeAutoRetrievalTimeout: (id) {},
      );
    } catch (ex) {
      emit(AuthError('فشل إرسال الرمز'));
    }
  }

  Future<void> _onVerifyOTP(VerifyPhoneOTP e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final cred = PhoneAuthProvider.credential(verificationId: e.verificationId, smsCode: e.otp);
      final userCred = await _fb.auth.signInWithCredential(cred);
      _timer?.cancel();
      emit(Authenticated(UserModel(id: userCred.user!.uid, phone: userCred.user!.phoneNumber)));
    } catch (ex) {
      emit(AuthError('رمز التحقق غير صحيح'));
    }
  }

  Future<void> _onRegister(RegisterWithEmail e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final cred = await _fb.auth.createUserWithEmailAndPassword(email: e.email.trim(), password: e.password);
      await _fb.userDoc(cred.user!.uid).set({
        'id': cred.user!.uid, 'email': e.email, 'phone': e.phone,
        'fullName': e.name, 'role': 'patient', 'createdAt': FieldValue.serverTimestamp(),
      });
      emit(Authenticated(UserModel(id: cred.user!.uid, email: e.email, fullName: e.name, phone: e.phone)));
    } on FirebaseAuthException catch (ex) {
      emit(AuthError(_msg(ex.code)));
    }
  }

  Future<void> _onResetPassword(ResetPassword e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _fb.auth.sendPasswordResetEmail(email: e.email.trim());
      emit(PasswordResetSent());
    } on FirebaseAuthException catch (ex) {
      emit(AuthError(_msg(ex.code)));
    }
  }

  Future<void> _onResendOTP(ResendOTP e, Emitter<AuthState> emit) async {
    add(LoginWithPhone(e.phone));
  }

  void _onGuest(EnterAsGuest e, Emitter<AuthState> emit) {
    emit(Authenticated(UserModel(id: "guest", fullName: "ضيف", email: "guest@sehatak.com")));
  }

  Future<void> _onLogout(Logout e, Emitter<AuthState> emit) async {
    _timer?.cancel();
    await _googleSignIn.signOut();
    await _fb.auth.signOut();
    emit(Unauthenticated());
  }

  String _msg(String code) {
    switch (code) {
      case 'invalid-email': return 'بريد غير صالح';
      case 'user-not-found': return 'مستخدم غير موجود';
      case 'wrong-password': return 'كلمة مرور خاطئة';
      case 'email-already-in-use': return 'البريد مستخدم';
      case 'weak-password': return 'كلمة مرور ضعيفة';
      case 'network-request-failed': return 'لا يوجد اتصال';
      case 'too-many-requests': return 'محاولات كثيرة';
      default: return code;
    }
  }
}
