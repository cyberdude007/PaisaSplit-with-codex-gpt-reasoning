import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:paisasplit/app_lock/domain/pin_hasher.dart';

void main() {
  group('PinHasher', () {
    test('generates salted hash and verifies matching PIN', () {
      final hasher = PinHasher(random: Random(1));

      final secret = hasher.generate('1234');

      expect(secret.saltBase64, isNotEmpty);
      expect(secret.hashBase64, isNotEmpty);
      final saltBytes = base64Decode(secret.saltBase64);
      expect(saltBytes.length, PinHasher.saltLength);
      expect(hasher.verify('1234', secret), isTrue);
    });

    test('fails verification for incorrect PIN', () {
      final hasher = PinHasher(random: Random(2));
      final secret = hasher.generate('9876');

      expect(hasher.verify('0000', secret), isFalse);
    });
  });
}
