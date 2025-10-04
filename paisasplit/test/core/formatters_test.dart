import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:paisasplit/app/theme/colors.dart';
import 'package:paisasplit/app/theme/theme.dart';
import 'package:paisasplit/core/formatters/currency_formatter.dart';
import 'package:paisasplit/core/formatters/date_utils.dart';

void main() {
  setUpAll(() async {
    Intl.defaultLocale = 'en_IN';
    await initializeDateFormatting('en_IN', null);
  });

  test('formats INR currency with lakh/crore grouping', () {
    const amountInPaise = 12345600; // ₹1,23,456.00
    final formatted = formatCurrencyFromPaise(amountInPaise);

    expect(formatted, '₹1,23,456.00');
  });

  test('formats compact INR currency using lakh shorthand', () {
    const amountInPaise = 12345600; // ₹1.2L
    final formatted = formatCompactCurrency(amountInPaise);

    expect(formatted, '₹1.2L');
  });

  test('formats dates using DD MMM YYYY pattern', () {
    final date = DateTime(2025, 9, 7);

    expect(formatDisplayDate(date), '07 Sep 2025');
  });

  test('computes Monday as the start of week and Sunday as end', () {
    final date = DateTime(2025, 9, 7); // Sunday

    expect(startOfWeek(date), DateTime(2025, 9, 1));
    expect(endOfWeek(date), DateTime(2025, 9, 7));
    expect(daysOfWeek(date).first, DateTime(2025, 9, 1));
    expect(daysOfWeek(date).last, DateTime(2025, 9, 7));
  });

  testWidgets('negative amount hint uses error token', (tester) async {
    const amount = -100;

    late Color? hintColor;

    await tester.pumpWidget(MaterialApp(
      theme: buildPaisaTheme(),
      home: Builder(
        builder: (context) {
          hintColor = negativeAmountHintColor(context, amount);
          return const SizedBox.shrink();
        },
      ),
    ));

    final theme = buildPaisaTheme();
    final tokens = theme.extension<PaisaColorTokens>();
    expect(hintColor, tokens?.stateError ?? theme.colorScheme.error);
  });
}
