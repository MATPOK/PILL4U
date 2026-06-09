import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/history_entry.dart';

void main() {
  group('HistoryEntry', () {
    test('fromJson rozróżnia wpis lokalny od odpowiedzi serwera', () {
      final local = HistoryEntry.fromJson({
        'id': 3,
        'api_id': 10,
        'medication_id': 1,
        'medication_name': 'Witamina C',
        'status': 'TAKEN',
        'taken_at': '2026-01-01T10:00:00.000Z',
      });

      expect(local.id, 3);
      expect(local.apiId, 10);
      expect(local.medicationId, 1);
      expect(local.status, 'TAKEN');

      final server = HistoryEntry.fromJson({
        'id': 55,
        'medicationId': 2,
        'medicationName': 'Ibuprom',
        'status': 'MISSED',
        'takenAt': '2026-01-02T11:00:00.000Z',
      });

      expect(server.id, isNull);
      expect(server.apiId, 55);
      expect(server.medicationId, 2);
      expect(server.medicationName, 'Ibuprom');
      expect(server.status, 'MISSED');
    });

    test('fromJson ma fallback nazwy leku, gdy brak pola', () {
      final h = HistoryEntry.fromJson({
        'id': 1,
        'medicationId': 2,
        'status': 'TAKEN',
        'takenAt': '2026-01-02T11:00:00.000Z',
      });

      expect(h.medicationName, 'Lek');
    });

    test('toApiJson zawiera klucze oczekiwane przez API i pomija lokalne', () {
      final h = HistoryEntry(
        medicationId: 1,
        medicationName: 'X',
        status: 'TAKEN',
        takenAt: '2026-01-01T10:00:00.000Z',
      );
      final json = h.toApiJson();

      expect(json['medicationId'], 1);
      expect(json['status'], 'TAKEN');
      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('api_id'), isFalse);
    });

    test('copyWith podmienia medicationId (mapowanie lokalne -> api) bez gubienia reszty', () {
      final h = HistoryEntry(
        id: 1,
        medicationId: 5,
        medicationName: 'X',
        status: 'TAKEN',
        takenAt: 't',
      );
      final copy = h.copyWith(medicationId: 42);

      expect(copy.medicationId, 42);
      expect(copy.medicationName, 'X');
      expect(copy.status, 'TAKEN');
      expect(copy.id, 1);
    });
  });
}
