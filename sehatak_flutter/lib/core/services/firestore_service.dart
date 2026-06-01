import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class FirestoreService {
  final FirebaseService _fb = FirebaseService();

  // الحصول على الأطباء
  Stream<QuerySnapshot> getDoctorsStream({String? specialization}) {
    Query query = _fb.doctorsCol.where('isAvailable', isEqualTo: true);
    if (specialization != null) query = query.where('specialization', isEqualTo: specialization);
    return query.orderBy('rating', descending: true).snapshots();
  }

  // الحصول على مواعيد المريض
  Stream<QuerySnapshot> getPatientAppointments(String patientId) {
    return _fb.appointmentsCol
        .where('patientId', isEqualTo: patientId)
        .orderBy('date', descending: true)
        .snapshots();
  }

  // حجز موعد
  Future<void> bookAppointment({
    required String patientId,
    required String doctorId,
    required String date,
    required String time,
    String? notes,
  }) async {
    await _fb.appointmentsCol.add({
      'patientId': patientId,
      'doctorId': doctorId,
      'date': date,
      'time': time,
      'status': 'pending',
      'notes': notes ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // الحصول على بيانات المستخدم
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _fb.userDoc(uid).get();
    return doc.exists ? doc.data() as Map<String, dynamic> : null;
  }

  // تحديث بيانات المستخدم
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    await _fb.userDoc(uid).update(data);
  }
}
