const List<String> _monthAbbreviations = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Formats [date] using the PaisaSplit display pattern `DD MMM YYYY`.
String formatDisplayDate(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  final day = normalized.day.toString().padLeft(2, '0');
  final month = _monthAbbreviations[normalized.month - 1];
  final year = normalized.year.toString();
  return '$day $month $year';
}

/// Returns the Monday of the week for the provided [date].
DateTime startOfWeek(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  final difference = (normalized.weekday - DateTime.monday) % DateTime.daysPerWeek;
  return normalized.subtract(Duration(days: difference));
}

/// Returns the Sunday of the week for the provided [date].
DateTime endOfWeek(DateTime date) {
  final start = startOfWeek(date);
  return start.add(const Duration(days: DateTime.daysPerWeek - 1));
}

/// Returns all calendar days for the week containing [date], starting Monday.
List<DateTime> daysOfWeek(DateTime date) {
  final start = startOfWeek(date);
  return List<DateTime>.generate(
    DateTime.daysPerWeek,
    (index) => start.add(Duration(days: index)),
  );
}
