import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/medication.dart';

void main() {
  group('Medication', () {
    test('fromJson interpretuje wiersz lokalny (zawiera klucz api_id)', () {
      final m = Medication.fromJson({
        'id': 5,
        'api_id': 42,
        'name': 'Witamina C',
        'dosage': '1000mg',
        'time': '09:00',
        'days': 'Pn',
      });

      expect(m.id, 5);
      expect(m.apiId, 42);
      expect(m.name, 'Witamina C');
      expect(m.days, 'Pn');
    });

    test('fromJson interpretuje odpowiedź serwera (id => apiId, brak lokalnego id)', () {
      final m = Medication.fromJson({
        'id': 99,
        'name': 'Ibuprom',
        'dosage': '200mg',
        'time': '12:00',
        'days': 'Wt',
      });

      expect(m.id, isNull, reason: 'Odpowiedź serwera nie ma lokalnego id');
      expect(m.apiId, 99);
    });

    test('toApiJson nie zawiera pól lokalnych (id, api_id)', () {
      final m = Medication(id: 1, apiId: 2, name: 'X', dosage: '1 tab', time: '08:00', days: 'Pn');
      final json = m.toApiJson();

      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('api_id'), isFalse);
      expect(json['name'], 'X');
      expect(json['dosage'], '1 tab');
    });

    test('toJson pomija null id oraz null apiId', () {
      final m = Medication(name: 'X', dosage: '1', time: '08:00', days: 'Pn');
      final json = m.toJson();

      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('api_id'), isFalse);
      expect(json['name'], 'X');
    });

    test('copyWith ustawia apiId zachowując pozostałe pola', () {
      final m = Medication(id: 1, name: 'X', dosage: '1', time: '08:00', days: 'Pn');
      final copy = m.copyWith(apiId: 7);

      expect(copy.apiId, 7);
      expect(copy.id, 1);
      expect(copy.name, 'X');
      expect(copy.time, '08:00');
    });
  });
}
