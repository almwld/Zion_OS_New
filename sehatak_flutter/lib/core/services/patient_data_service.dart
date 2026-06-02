import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PatientDataService {
  static final PatientDataService _instance = PatientDataService._internal();
  factory PatientDataService() => _instance;
  PatientDataService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ========== القراءات الحيوية ==========
  Future<List<Map<String, dynamic>>> getReadings(String type) async {
    final data = _prefs?.getString('readings_$type') ?? '[]';
    return List<Map<String, dynamic>>.from(jsonDecode(data));
  }

  Future<void> addReading(String type, Map<String, dynamic> reading) async {
    final readings = await getReadings(type);
    reading['date'] = DateTime.now().toIso8601String();
    readings.insert(0, reading);
    await _prefs?.setString('readings_$type', jsonEncode(readings));
  }

  // ========== الأدوية ==========
  Future<List<Map<String, dynamic>>> getMedications() async {
    final data = _prefs?.getString('medications') ?? '[]';
    return List<Map<String, dynamic>>.from(jsonDecode(data));
  }

  Future<void> addMedication(Map<String, dynamic> med) async {
    final meds = await getMedications();
    meds.add(med);
    await _prefs?.setString('medications', jsonEncode(meds));
  }

  Future<void> toggleMedication(int index, bool taken) async {
    final meds = await getMedications();
    meds[index]['taken'] = taken;
    meds[index]['history'] ??= [];
    meds[index]['history'].add({'date': DateTime.now().toIso8601String(), 'taken': taken});
    await _prefs?.setString('medications', jsonEncode(meds));
  }

  // ========== المواعيد ==========
  Future<List<Map<String, dynamic>>> getAppointments() async {
    final data = _prefs?.getString('appointments') ?? '[]';
    return List<Map<String, dynamic>>.from(jsonDecode(data));
  }

  Future<void> addAppointment(Map<String, dynamic> apt) async {
    final apts = await getAppointments();
    apts.add(apt);
    await _prefs?.setString('appointments', jsonEncode(apts));
  }

  // ========== الملاحظات ==========
  Future<List<Map<String, dynamic>>> getNotes() async {
    final data = _prefs?.getString('notes') ?? '[]';
    return List<Map<String, dynamic>>.from(jsonDecode(data));
  }

  Future<void> addNote(Map<String, dynamic> note) async {
    final notes = await getNotes();
    note['date'] = DateTime.now().toIso8601String();
    notes.insert(0, note);
    await _prefs?.setString('notes', jsonEncode(notes));
  }

  // ========== التحديات ==========
  Future<Map<String, dynamic>> getChallenges() async {
    final data = _prefs?.getString('challenges') ?? '{}';
    return jsonDecode(data);
  }

  Future<void> joinChallenge(String id) async {
    final challenges = await getChallenges();
    challenges[id] = {'joined': DateTime.now().toIso8601String(), 'progress': 0.0};
    await _prefs?.setString('challenges', jsonEncode(challenges));
  }

  Future<void> updateProgress(String id, double progress) async {
    final challenges = await getChallenges();
    challenges[id]['progress'] = progress;
    await _prefs?.setString('challenges', jsonEncode(challenges));
  }
}
