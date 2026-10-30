import 'package:careerpulse_ai/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.email', () {
    test('accepts valid addresses', () {
      expect(Validators.email('a@b.co'), isNull);
      expect(Validators.email('  user.name@mail.example.com '), isNull);
    });

    test('rejects invalid addresses', () {
      for (final bad in [null, '', 'abc', 'a@b', '@b.com', 'a b@c.com']) {
        expect(Validators.email(bad), isNotNull, reason: '"$bad" should fail');
      }
    });
  });

  group('Validators.password', () {
    test('requires at least 8 characters', () {
      expect(Validators.password('1234567'), isNotNull);
      expect(Validators.password(null), isNotNull);
      expect(Validators.password('12345678'), isNull);
    });
  });

  group('Validators.required', () {
    test('rejects blank values and names the field', () {
      final v = Validators.required('name');
      expect(v('   '), 'Enter your name');
      expect(v(null), 'Enter your name');
      expect(v('Asha'), isNull);
    });
  });
}