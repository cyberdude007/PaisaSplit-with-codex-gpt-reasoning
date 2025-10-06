import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:paisasplit/app_lock/domain/app_lock_authenticator.dart';
import 'package:paisasplit/app_lock/domain/pin_hasher.dart';
import 'package:paisasplit/app_lock/presentation/app_lock_screen.dart';
import 'package:paisasplit/app_lock/infrastructure/local_auth_app_lock_authenticator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _FakeAppLockAuthenticator implements AppLockAuthenticator {
  _FakeAppLockAuthenticator({
    required this.result,
    this.canCheck = true,
    this.isSupported = true,
  });

  final AppLockAuthResult result;
  final bool canCheck;
  final bool isSupported;
  int authenticateCount = 0;

  @override
  Future<AppLockAuthResult> authenticate() async {
    authenticateCount += 1;
    return result;
  }

  @override
  Future<bool> canCheckBiometrics() async => canCheck;

  @override
  Future<bool> isDeviceSupported() async => isSupported;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('biometric success unlocks overlay', (tester) async {
    final hasher = PinHasher(random: Random(3));
    final secret = hasher.generate('2580');
    SharedPreferences.setMockInitialValues({
      'app_lock.enabled': true,
      'app_lock.pin.salt': secret.saltBase64,
      'app_lock.pin.hash': secret.hashBase64,
    });

    final authenticator = _FakeAppLockAuthenticator(
      result: const AppLockAuthResult.success(),
      canCheck: true,
      isSupported: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLockAuthenticatorProvider.overrideWithValue(authenticator),
        ],
        child: const MaterialApp(home: Scaffold(body: AppLockOverlay())),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(authenticator.authenticateCount, 1);
    expect(find.text('Unlock PaisaSplit'), findsNothing);
  });

  testWidgets('incorrect PIN shows inline error', (tester) async {
    final hasher = PinHasher(random: Random(4));
    final secret = hasher.generate('1234');
    SharedPreferences.setMockInitialValues({
      'app_lock.enabled': true,
      'app_lock.pin.salt': secret.saltBase64,
      'app_lock.pin.hash': secret.hashBase64,
    });

    final authenticator = _FakeAppLockAuthenticator(
      result: const AppLockAuthResult.failure(
        'Authentication failed. Try again.',
      ),
      canCheck: false,
      isSupported: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLockAuthenticatorProvider.overrideWithValue(authenticator),
        ],
        child: const MaterialApp(home: Scaffold(body: AppLockOverlay())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Unlock PaisaSplit'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pin-key-0')));
    await tester.tap(find.byKey(const Key('pin-key-0')));
    await tester.tap(find.byKey(const Key('pin-key-0')));
    await tester.tap(find.byKey(const Key('pin-key-0')));
    await tester.pump();

    expect(find.text('Incorrect PIN. Try again.'), findsOneWidget);
  });
}
