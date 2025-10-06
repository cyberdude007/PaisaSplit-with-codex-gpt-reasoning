import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/app_lock_controller.dart';
import '../application/app_lock_state.dart';

class AppLockOverlay extends ConsumerWidget {
  const AppLockOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AppLockState>(appLockControllerProvider, (previous, next) {
      if (next.shouldPromptBiometric &&
          next.isLocked &&
          !next.isAuthenticating) {
        Future<void>.microtask(
          () => ref
              .read(appLockControllerProvider.notifier)
              .authenticateWithBiometrics(),
        );
      }
    });

    final state = ref.watch(appLockControllerProvider);
    final shouldShow = state.isInitialized && state.isEnabled && state.isLocked;
    if (!shouldShow) {
      return const SizedBox.shrink();
    }
    return const _AppLockScreen();
  }
}

class _AppLockScreen extends ConsumerStatefulWidget {
  const _AppLockScreen();

  @override
  ConsumerState<_AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<_AppLockScreen> {
  static const _pinLength = 4;

  String _pinInput = '';

  void _onDigitTap(String digit) {
    final state = ref.read(appLockControllerProvider);
    if (_pinInput.length >= _pinLength || state.isVerifyingPin) {
      return;
    }
    ref.read(appLockControllerProvider.notifier).clearError();
    setState(() {
      _pinInput = '$_pinInput$digit';
    });
    if (_pinInput.length == _pinLength) {
      _submitPin(_pinInput);
    }
  }

  void _onBackspace() {
    if (_pinInput.isEmpty) {
      return;
    }
    ref.read(appLockControllerProvider.notifier).clearError();
    setState(() {
      _pinInput = _pinInput.substring(0, _pinInput.length - 1);
    });
  }

  Future<void> _submitPin(String pin) async {
    final controller = ref.read(appLockControllerProvider.notifier);
    final success = await controller.verifyPin(pin);
    if (!mounted) {
      return;
    }
    if (success) {
      setState(() {
        _pinInput = '';
      });
    } else {
      setState(() {
        _pinInput = '';
      });
    }
  }

  void _switchToPin() {
    ref.read(appLockControllerProvider.notifier).showPinPad();
    setState(() {
      _pinInput = '';
    });
  }

  void _switchToBiometric() {
    ref.read(appLockControllerProvider.notifier).showBiometricPrompt();
    setState(() {
      _pinInput = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appLockControllerProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox.expand(
      child: Material(
        color: colorScheme.surface,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 72,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Unlock PaisaSplit',
                      style: theme.textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    if (state.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          state.errorMessage!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (state.showPinPad)
                      _PinEntry(
                        pinLength: _pinLength,
                        inputLength: _pinInput.length,
                        onDigitTap: _onDigitTap,
                        onBackspace: _onBackspace,
                        isVerifying: state.isVerifyingPin,
                        canUseBiometric: state.canCheckBiometrics,
                        onUseBiometric: _switchToBiometric,
                      )
                    else
                      _BiometricPrompt(
                        isAuthenticating: state.isAuthenticating,
                        onAuthenticate: () => ref
                            .read(appLockControllerProvider.notifier)
                            .authenticateWithBiometrics(),
                        canUsePin: state.hasPin,
                        onUsePin: _switchToPin,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BiometricPrompt extends StatelessWidget {
  const _BiometricPrompt({
    required this.isAuthenticating,
    required this.onAuthenticate,
    required this.canUsePin,
    required this.onUsePin,
  });

  final bool isAuthenticating;
  final VoidCallback onAuthenticate;
  final bool canUsePin;
  final VoidCallback onUsePin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isAuthenticating)
          const Padding(
            padding: EdgeInsets.only(bottom: 24),
            child: CircularProgressIndicator(),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: FilledButton.icon(
              key: const Key('app-lock-authenticate-button'),
              onPressed: onAuthenticate,
              icon: const Icon(Icons.fingerprint),
              label: const Text('Use biometrics'),
            ),
          ),
        if (canUsePin)
          TextButton(
            key: const Key('app-lock-use-pin'),
            onPressed: onUsePin,
            child: Text(
              'Use PIN instead',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }
}

class _PinEntry extends StatelessWidget {
  const _PinEntry({
    required this.pinLength,
    required this.inputLength,
    required this.onDigitTap,
    required this.onBackspace,
    required this.isVerifying,
    required this.canUseBiometric,
    required this.onUseBiometric,
  });

  final int pinLength;
  final int inputLength;
  final ValueChanged<String> onDigitTap;
  final VoidCallback onBackspace;
  final bool isVerifying;
  final bool canUseBiometric;
  final VoidCallback onUseBiometric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PinDots(pinLength: pinLength, filled: inputLength),
        const SizedBox(height: 24),
        if (isVerifying)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        _PinPad(onDigitPressed: onDigitTap, onBackspace: onBackspace),
        if (canUseBiometric)
          TextButton(
            key: const Key('app-lock-use-biometric'),
            onPressed: onUseBiometric,
            child: Text(
              'Try biometrics',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }
}

class _PinDots extends StatelessWidget {
  const _PinDots({required this.pinLength, required this.filled});

  final int pinLength;
  final int filled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pinLength, (index) {
        final isFilled = index < filled;
        return Container(
          width: 16,
          height: 16,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: isFilled
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

class _PinPad extends StatelessWidget {
  const _PinPad({required this.onDigitPressed, required this.onBackspace});

  final ValueChanged<String> onDigitPressed;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    const digits = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];

    return Column(
      children: [
        for (final row in digits)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: row
                  .map(
                    (digit) => _PinButton(
                      label: digit,
                      onPressed: () => onDigitPressed(digit),
                    ),
                  )
                  .toList(),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 72),
            _PinButton(label: '0', onPressed: () => onDigitPressed('0')),
            _PinIconButton(
              icon: Icons.backspace_outlined,
              onPressed: onBackspace,
            ),
          ],
        ),
      ],
    );
  }
}

class _PinButton extends StatelessWidget {
  const _PinButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 72,
      height: 56,
      child: FilledButton.tonal(
        key: Key('pin-key-$label'),
        onPressed: onPressed,
        child: Text(label, style: theme.textTheme.headlineMedium),
      ),
    );
  }
}

class _PinIconButton extends StatelessWidget {
  const _PinIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 56,
      child: IconButton(
        key: const Key('pin-backspace'),
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}
