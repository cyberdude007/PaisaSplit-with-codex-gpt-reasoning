import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<String?> showAppLockPinSetupSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) => const _AppLockPinSetupSheet(),
  );
}

class _AppLockPinSetupSheet extends StatefulWidget {
  const _AppLockPinSetupSheet();

  @override
  State<_AppLockPinSetupSheet> createState() => _AppLockPinSetupSheetState();
}

class _AppLockPinSetupSheetState extends State<_AppLockPinSetupSheet> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  final _pinFocusNode = FocusNode();
  final _confirmFocusNode = FocusNode();

  String? _errorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    _pinFocusNode.dispose();
    _confirmFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final pin = _pinController.text;
    final confirmPin = _confirmController.text;
    if (pin.length != 4 || confirmPin.length != 4) {
      setState(() {
        _errorMessage = 'Enter and confirm a 4-digit PIN.';
      });
      return;
    }
    if (pin != confirmPin) {
      setState(() {
        _errorMessage = 'PINs do not match. Try again.';
      });
      return;
    }
    Navigator.of(context).pop(pin);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: bottomInset + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Set App Lock PIN', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Create a 4-digit PIN to unlock PaisaSplit when biometrics are unavailable.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _pinController,
            focusNode: _pinFocusNode,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            obscureText: true,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (_) => _confirmFocusNode.requestFocus(),
            decoration: const InputDecoration(
              labelText: 'PIN',
              counterText: '',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmController,
            focusNode: _confirmFocusNode,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            obscureText: true,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              labelText: 'Confirm PIN',
              counterText: '',
            ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              child: const Text('Save PIN'),
            ),
          ),
        ],
      ),
    );
  }
}
