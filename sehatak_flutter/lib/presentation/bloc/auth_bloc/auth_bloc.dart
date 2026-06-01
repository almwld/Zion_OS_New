import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/user_models/user_model.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}
class LoginWithEmail extends AuthEvent {
  final String email, password;
  const LoginWithEmail({required this.email, required this.password});
}
class LoginWithPhone extends AuthEvent {
  final String phone;
  const LoginWithPhone(this.phone);
}
class VerifyPhoneOTP extends AuthEvent {
  final String verificationId, otp;
  const VerifyPhoneOTP({required this.verificationId, required this.otp});
}
class RegisterWithEmail extends AuthEvent {
  final String name, email, phone, password;
  const RegisterWithEmail({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
  });
}
class ResetPassword extends AuthEvent {
  final String email;
  const ResetPassword(this.email);
}
class Logout extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  const AuthState();
}
class AuthInitial extends AuthState {
  @override List<Object?> get props => [];
}
class AuthLoading extends AuthState {
  @override List<Object?> get props => [];
}
class AuthCodeSent extends AuthState {
  final String verificationId;
  const AuthCodeSent(this.verificationId);
  @override List<Object?> get props => [verificationId];
}
class Authenticated extends AuthState {
  final UserModel user;
  const Authenticated(this.user);
  @override List<Object?> get props => [user];
}
class Unauthenticated extends AuthState {
  @override List<Object?> get props => [];
}
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override List<Object?> get props => [message];
}
class PasswordResetSent extends AuthState {
  @override List<Object?> get props => [];
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseService _fb = FirebaseService();

  AuthBloc() : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginWithEmail>(_onLoginWithEmail);
    on<LoginWithPhone>(_onLoginWithPhone);
    on<VerifyPhoneOTP>(_onVerifyPhoneOTP);
    on<RegisterWithEmail>(_onRegister);
    on<ResetPassword>(_onResetPassword);
    on<Logout>(_onLogout);
  }

  void _onAppStarted(AppStarted e, Emitter<AuthState> emit) {
    final user = _fb.currentUser;
    if (user != null) {
      emit(Authenticated(UserModel(
        id: user.uid,
        email: user.email,
        phone: user.phoneNumber,
        fullName: user.displayName ?? 'مستخدم',
      )));
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginWithEmail(LoginWithEmail e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final cred = await _fb.auth.signInWithEmailAndPassword(
        email: e.email.trim(),
        password: e.password,
      );
      emit(Authenticated(UserModel(
        id: cred.user!.uid,
        email: e.email,
        fullName: cred.user!.displayName ?? 'مستخدم',
      )));
    } on FirebaseAuthException catch (ex) {
      emit(AuthError(_getMessage(ex.code)));
    }
  }

  Future<void> _onLoginWithPhone(LoginWithPhone e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _fb.auth.verifyPhoneNumber(
        phoneNumber: '+967${e.phone}',
        verificationCompleted: (cred) async {
          final user = await _fb.auth.signInWithCredential(cred);
          emit(Authenticated(UserModel(id: user.user!.uid, phone: e.phone)));
        },
        verificationFailed: (ex) => emit(AuthError(ex.message ?? 'خطأ')),
        codeSent: (id, token) => emit(AuthCodeSent(id)),
        codeAutoRetrievalTimeout: (id) {},
      );
    } catch (ex) {
      emit(AuthError('فشل إرسال رمز التحقق'));
    }
  }

  Future<void> _onVerifyPhoneOTP(VerifyPhoneOTP e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final cred = PhoneAuthProvider.credential(verificationId: e.verificationId, smsCode: e.otp);
      final user = await _fb.auth.signInWithCredential(cred);
      emit(Authenticated(UserModel(id: user.user!.uid, phone: user.user!.phoneNumber)));
    } catch (ex) {
      emit(AuthError('رمز التحقق غير صحيح'));
    }
  }

  Future<void> _onRegister(RegisterWithEmail e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final cred = await _fb.auth.createUserWithEmailAndPassword(
        email: e.email.trim(),
        password: e.password,
      );
      await _fb.userDoc(cred.user!.uid).set({
        'id': cred.user!.uid,
        'email': e.email,
        'phone': e.phone,
        'fullName': e.name,
        'role': 'patient',
        'createdAt': FieldValue.serverTimestamp(),
      });
      emit(Authenticated(UserModel(
        id: cred.user!.uid,
        email: e.email,
        phone: e.phone,
        fullName: e.name,
      )));
    } on FirebaseAuthException catch (ex) {
      emit(AuthError(_getMessage(ex.code)));
    }
  }

  Future<void> _onResetPassword(ResetPassword e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _fb.auth.sendPasswordResetEmail(email: e.email.trim());
      emit(PasswordResetSent());
    } on FirebaseAuthException catch (ex) {
      emit(AuthError(_getMessage(ex.code)));
    }
  }

  Future<void> _onLogout(Logout e, Emitter<AuthState> emit) async {
    await _fb.auth.signOut();
    emit(Unauthenticated());
  }

  String _getMessage(String code) {
    switch (code) {
      case 'user-not-found': return 'المستخدم غير موجود';
      case 'wrong-password': return 'كلمة مرور خاطئة';
      case 'email-already-in-use': return 'الإيميل مستخدم مسبقاً';
      case 'weak-password': return 'كلمة المرور ضعيفة';
      case 'invalid-email': return 'إيميل غير صالح';
      default: return 'حدث خطأ: $code';
    }
  }
}
