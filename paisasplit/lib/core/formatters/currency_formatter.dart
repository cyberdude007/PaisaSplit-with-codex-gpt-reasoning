import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme/colors.dart';

final NumberFormat _currencyFormatter = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 2,
);

num _toRupees(int amountInPaise) => amountInPaise / 100;

/// Formats an [amountInPaise] to an INR currency string using lakh/crore grouping.
String formatCurrencyFromPaise(int amountInPaise) {
  final rupees = _toRupees(amountInPaise);
  return _currencyFormatter.format(rupees);
}

/// Formats an [amountInPaise] into a compact INR string (e.g. `₹1.2L`).
String formatCompactCurrency(int amountInPaise) {
  final rupees = _toRupees(amountInPaise).toDouble();
  final sign = rupees < 0 ? '-' : '';
  final absValue = rupees.abs();

  String suffix;
  double divisor;

  if (absValue >= 10000000) {
    suffix = 'Cr';
    divisor = 10000000;
  } else if (absValue >= 100000) {
    suffix = 'L';
    divisor = 100000;
  } else if (absValue >= 1000) {
    suffix = 'K';
    divisor = 1000;
  } else {
    return formatCurrencyFromPaise(amountInPaise);
  }

  final scaled = absValue / divisor;
  final decimals = scaled >= 100 ? 0 : 1;
  var number = scaled.toStringAsFixed(decimals);
  if (number.endsWith('.0')) {
    number = number.substring(0, number.length - 2);
  }

  return '$sign₹$number$suffix';
}

/// Returns a color hint for negative amounts using the theme tokens.
Color? negativeAmountHintColor(BuildContext context, int amountInPaise) {
  if (amountInPaise >= 0) {
    return null;
  }

  final theme = Theme.of(context);
  final tokens = theme.extension<PaisaColorTokens>();
  return tokens?.stateError ?? theme.colorScheme.error;
}

/// Convenience flag to check if an [amountInPaise] represents a debit value.
bool isNegativeAmount(int amountInPaise) => amountInPaise < 0;
