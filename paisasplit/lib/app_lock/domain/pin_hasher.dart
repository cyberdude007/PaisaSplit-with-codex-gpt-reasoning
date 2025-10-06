import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class PinHasher {
  PinHasher({Random? random}) : _random = random ?? Random.secure();

  static const int saltLength = 16;

  final Random _random;

  PinSecret generate(String pin) {
    final salt = Uint8List(saltLength);
    for (var i = 0; i < saltLength; i++) {
      salt[i] = _random.nextInt(256);
    }

    final digest = sha256.convert(_saltedBytes(salt, pin));
    return PinSecret(
      saltBase64: base64Encode(salt),
      hashBase64: base64Encode(digest.bytes),
    );
  }

  bool verify(String pin, PinSecret secret) {
    if (secret.isEmpty) {
      return false;
    }
    try {
      final salt = base64Decode(secret.saltBase64);
      final storedHash = base64Decode(secret.hashBase64);
      final digest = sha256.convert(_saltedBytes(salt, pin));
      return _constantTimeEquals(digest.bytes, storedHash);
    } on FormatException {
      return false;
    }
  }

  List<int> _saltedBytes(Uint8List salt, String pin) {
    final pinBytes = utf8.encode(pin);
    return <int>[...salt, ...pinBytes];
  }

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}

class PinSecret {
  const PinSecret({required this.saltBase64, required this.hashBase64});

  final String saltBase64;
  final String hashBase64;

  bool get isEmpty => saltBase64.isEmpty || hashBase64.isEmpty;
}
