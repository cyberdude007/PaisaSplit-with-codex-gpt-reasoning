import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef Now = DateTime Function();

final nowProvider = Provider<Now>((ref) {
  return DateTime.now;
});
