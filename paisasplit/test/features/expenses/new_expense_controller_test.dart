import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:paisasplit/features/expenses/data/expense_models.dart';
import 'package:paisasplit/features/expenses/data/expense_repository.dart';
import 'package:paisasplit/features/expenses/presentation/new_expense_controller.dart';

class _FakeExpenseRepository implements ExpenseRepository {
  _FakeExpenseRepository(this.formData);

  final ExpenseFormData formData;
  ExpenseDraft? lastDraft;
  bool shouldThrow = false;

  @override
  Future<String> createExpense(ExpenseDraft draft) async {
    if (shouldThrow) {
      throw Exception('failed');
    }
    lastDraft = draft;
    return 'fake';
  }

  @override
  Future<void> deleteExpense(String expenseId) async {}

  @override
  Future<ExpenseFormData> loadFormData() async => formData;

  @override
  Future<void> updateExpense(ExpenseDraft draft) async {}
}

void main() {
  const formData = ExpenseFormData(
    groups: [
      ExpenseGroupOption(
        id: 'g1',
        name: 'Trip',
        members: [
          GroupMemberOption(id: 'me', name: 'Me'),
          GroupMemberOption(id: 'm_anu', name: 'Anu'),
        ],
      ),
    ],
    accounts: [
      ExpenseAccountOption(id: 'acc_default', name: 'Default Account'),
    ],
  );

  late _FakeExpenseRepository fakeRepository;
  late ProviderContainer container;

  setUp(() {
    fakeRepository = _FakeExpenseRepository(formData);
    container = ProviderContainer(
      overrides: [
        expenseRepositoryProvider.overrideWithValue(fakeRepository),
        newExpenseFormDataProvider.overrideWithValue(formData),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('initial state selects defaults and zero amount', () {
    final state = container.read(newExpenseControllerProvider);
    expect(state.kind, ExpenseKind.split);
    expect(state.selectedGroupId, 'g1');
    expect(state.selectedAccountId, 'acc_default');
    expect(state.memberSplits, hasLength(2));
    expect(state.amountPaise, isNull);
  });

  test('updateAmount recalculates equal split', () {
    final notifier = container.read(newExpenseControllerProvider.notifier);
    notifier.updateAmount('120');

    final state = container.read(newExpenseControllerProvider);
    expect(state.amountPaise, 12000);
    expect(state.memberSplits.map((m) => m.sharePaise).toList(), [6000, 6000]);
  });

  test('exact split mismatch triggers inline error', () {
    final notifier = container.read(newExpenseControllerProvider.notifier);
    notifier.updateAmount('120');
    notifier.selectSplitMethod(SplitMethod.exact);
    notifier.updateExactShare('me', '50');
    notifier.updateExactShare('m_anu', '60');

    final state = container.read(newExpenseControllerProvider);
    expect(state.exactSplitError, isNotNull);
  });

  test('submit fails when amount missing', () async {
    final notifier = container.read(newExpenseControllerProvider.notifier);
    final result = await notifier.submit();

    expect(result, isFalse);
    final state = container.read(newExpenseControllerProvider);
    expect(state.hasTriedSubmit, isTrue);
  });

  test('submit succeeds and posts draft to repository', () async {
    final notifier = container.read(newExpenseControllerProvider.notifier);
    notifier.updateAmount('240');
    notifier.updateDescription('Ferry');
    notifier.updateCategory('Transport');

    final result = await notifier.submit();

    expect(result, isTrue);
    expect(fakeRepository.lastDraft, isNotNull);
    expect(fakeRepository.lastDraft!.amountPaise, 24000);
  });

  test('submit reports error when repository throws', () async {
    fakeRepository.shouldThrow = true;
    final notifier = container.read(newExpenseControllerProvider.notifier);
    notifier.updateAmount('100');
    notifier.updateDescription('Snacks');
    notifier.updateCategory('Food');

    final result = await notifier.submit();

    expect(result, isFalse);
    final state = container.read(newExpenseControllerProvider);
    expect(state.submissionError, "Couldn't save. Retry.");
  });
}
