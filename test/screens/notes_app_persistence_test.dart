import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:project_zion/screens/apps/notes_app.dart';

void main() {
  testWidgets('restores persisted notes after app restart', (tester) async {
    SharedPreferences.setMockInitialValues({
      'notes': jsonEncode([
        {
          'id': 'note-1',
          'title': 'Persisted note',
          'content': 'Restored after restart',
          'color': 0,
          'timestamp': '2026-10-03T00:00:00.000Z',
        },
      ]),
    });

    await tester.pumpWidget(const MaterialApp(home: NotesApp()));
    await tester.pumpAndSettle();

    expect(find.text('Persisted note'), findsOneWidget);
    expect(find.text('Restored after restart'), findsOneWidget);
  });
}
