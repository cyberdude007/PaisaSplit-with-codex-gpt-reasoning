class AppLockState {
  const AppLockState({
    required this.isInitialized,
    required this.isEnabled,
    required this.isLocked,
    required this.hasPin,
    required this.canCheckBiometrics,
    required this.showPinPad,
    required this.isAuthenticating,
    required this.isVerifyingPin,
    required this.shouldPromptBiometric,
    this.errorMessage,
  });

  const AppLockState.initial()
    : this(
        isInitialized: false,
        isEnabled: false,
        isLocked: false,
        hasPin: false,
        canCheckBiometrics: false,
        showPinPad: false,
        isAuthenticating: false,
        isVerifyingPin: false,
        shouldPromptBiometric: false,
        errorMessage: null,
      );

  final bool isInitialized;
  final bool isEnabled;
  final bool isLocked;
  final bool hasPin;
  final bool canCheckBiometrics;
  final bool showPinPad;
  final bool isAuthenticating;
  final bool isVerifyingPin;
  final bool shouldPromptBiometric;
  final String? errorMessage;

  static const _sentinel = Object();

  AppLockState copyWith({
    bool? isInitialized,
    bool? isEnabled,
    bool? isLocked,
    bool? hasPin,
    bool? canCheckBiometrics,
    bool? showPinPad,
    bool? isAuthenticating,
    bool? isVerifyingPin,
    bool? shouldPromptBiometric,
    Object? errorMessage = _sentinel,
  }) {
    return AppLockState(
      isInitialized: isInitialized ?? this.isInitialized,
      isEnabled: isEnabled ?? this.isEnabled,
      isLocked: isLocked ?? this.isLocked,
      hasPin: hasPin ?? this.hasPin,
      canCheckBiometrics: canCheckBiometrics ?? this.canCheckBiometrics,
      showPinPad: showPinPad ?? this.showPinPad,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
      isVerifyingPin: isVerifyingPin ?? this.isVerifyingPin,
      shouldPromptBiometric:
          shouldPromptBiometric ?? this.shouldPromptBiometric,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
