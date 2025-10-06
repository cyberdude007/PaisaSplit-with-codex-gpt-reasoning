import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters/currency_formatter.dart';
import '../../accounts/data/account_repo.dart';
import '../data/expense_models.dart';
import '../data/expense_repository.dart';

enum ExpenseKind { split, individual }

enum SplitMethod { equal, exact }

class MemberSplitState extends Equatable {
  const MemberSplitState({
    required this.memberId,
    required this.memberName,
    this.sharePaise = 0,
    this.exactInput = '',
  });

  final String memberId;
  final String memberName;
  final int sharePaise;
  final String exactInput;

  MemberSplitState copyWith({int? sharePaise, String? exactInput}) {
    return MemberSplitState(
      memberId: memberId,
      memberName: memberName,
      sharePaise: sharePaise ?? this.sharePaise,
      exactInput: exactInput ?? this.exactInput,
    );
  }

  @override
  List<Object?> get props => [memberId, memberName, sharePaise, exactInput];
}

class NewExpenseState extends Equatable {
  const NewExpenseState({
    required this.kind,
    required this.splitMethod,
    required this.groups,
    required this.accounts,
    required this.memberSplits,
    required this.selectedGroupId,
    required this.selectedAccountId,
    required this.selectedPayerId,
    required this.date,
    required this.amountInput,
    this.amountPaise,
    required this.description,
    required this.category,
    required this.notes,
    required this.isSaving,
    required this.hasTriedSubmit,
    this.exactSplitError,
    this.submissionError,
  });

  final ExpenseKind kind;
  final SplitMethod splitMethod;
  final List<ExpenseGroupOption> groups;
  final List<ExpenseAccountOption> accounts;
  final List<MemberSplitState> memberSplits;
  final String? selectedGroupId;
  final String? selectedAccountId;
  final String? selectedPayerId;
  final DateTime date;
  final String amountInput;
  final int? amountPaise;
  final String description;
  final String category;
  final String notes;
  final bool isSaving;
  final bool hasTriedSubmit;
  final String? exactSplitError;
  final String? submissionError;

  ExpenseGroupOption? get selectedGroup =>
      groups.firstWhereOrNull((group) => group.id == selectedGroupId);

  ExpenseAccountOption? get selectedAccount =>
      accounts.firstWhereOrNull((account) => account.id == selectedAccountId);

  bool get hasAmountError =>
      amountPaise == null || amountPaise == 0 || amountPaise!.isNegative;

  bool get hasGroupError => selectedGroupId == null || selectedGroupId!.isEmpty;

  bool get hasPayerError => selectedPayerId == null || selectedPayerId!.isEmpty;

  bool get isExactMode => splitMethod == SplitMethod.exact;

  String get amountDisplay =>
      amountPaise == null ? '₹0.00' : formatCurrencyFromPaise(amountPaise!);

  NewExpenseState copyWith({
    ExpenseKind? kind,
    SplitMethod? splitMethod,
    List<MemberSplitState>? memberSplits,
    String? selectedGroupId,
    String? selectedAccountId,
    String? selectedPayerId,
    DateTime? date,
    String? amountInput,
    int? amountPaise,
    String? description,
    String? category,
    String? notes,
    bool? isSaving,
    bool? hasTriedSubmit,
    String? exactSplitError,
    String? submissionError,
  }) {
    return NewExpenseState(
      kind: kind ?? this.kind,
      splitMethod: splitMethod ?? this.splitMethod,
      groups: groups,
      accounts: accounts,
      memberSplits: memberSplits ?? this.memberSplits,
      selectedGroupId: selectedGroupId ?? this.selectedGroupId,
      selectedAccountId: selectedAccountId ?? this.selectedAccountId,
      selectedPayerId: selectedPayerId ?? this.selectedPayerId,
      date: date ?? this.date,
      amountInput: amountInput ?? this.amountInput,
      amountPaise: amountPaise ?? this.amountPaise,
      description: description ?? this.description,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      isSaving: isSaving ?? this.isSaving,
      hasTriedSubmit: hasTriedSubmit ?? this.hasTriedSubmit,
      exactSplitError: exactSplitError,
      submissionError: submissionError,
    );
  }

  @override
  List<Object?> get props => [
    kind,
    splitMethod,
    groups,
    accounts,
    memberSplits,
    selectedGroupId,
    selectedAccountId,
    selectedPayerId,
    date,
    amountInput,
    amountPaise,
    description,
    category,
    notes,
    isSaving,
    hasTriedSubmit,
    exactSplitError,
    submissionError,
  ];
}

class NewExpenseController extends StateNotifier<NewExpenseState> {
  NewExpenseController({
    required this.repository,
    required ExpenseFormData formData,
  }) : super(_buildInitialState(formData: formData)) {
    _recalculateEqualSplits();
  }

  final ExpenseRepository repository;

  static NewExpenseState _buildInitialState({
    required ExpenseFormData formData,
  }) {
    final groups = formData.groups;
    final accounts = formData.accounts;
    final initialGroupId = groups.isEmpty ? null : groups.first.id;
    final initialGroup = groups.firstWhereOrNull(
      (group) => group.id == initialGroupId,
    );
    final members = initialGroup?.members ?? const <GroupMemberOption>[];
    final payerId =
        members
            .firstWhereOrNull((member) => member.id == currentUserMemberId)
            ?.id ??
        (members.isEmpty ? null : members.first.id);
    final initialAccountId = accounts.isEmpty ? null : accounts.first.id;

    return NewExpenseState(
      kind: ExpenseKind.split,
      splitMethod: SplitMethod.equal,
      groups: groups,
      accounts: accounts,
      memberSplits: members
          .map(
            (member) =>
                MemberSplitState(memberId: member.id, memberName: member.name),
          )
          .toList(growable: false),
      selectedGroupId: initialGroupId,
      selectedAccountId: initialAccountId,
      selectedPayerId: payerId,
      date: DateTime.now(),
      amountInput: '',
      amountPaise: null,
      description: '',
      category: '',
      notes: '',
      isSaving: false,
      hasTriedSubmit: false,
      exactSplitError: null,
      submissionError: null,
    );
  }

  void switchKind(ExpenseKind kind) {
    if (state.kind == kind) {
      return;
    }
    state = state.copyWith(
      kind: kind,
      hasTriedSubmit: false,
      submissionError: null,
      exactSplitError: null,
    );
    if (kind == ExpenseKind.split && state.splitMethod == SplitMethod.equal) {
      _recalculateEqualSplits();
    }
  }

  void selectSplitMethod(SplitMethod method) {
    if (state.splitMethod == method) {
      return;
    }
    final updatedMembers = state.memberSplits
        .map(
          (member) => member.copyWith(
            exactInput: method == SplitMethod.exact
                ? member.sharePaise == 0
                      ? ''
                      : _formatPaiseAsInput(member.sharePaise)
                : member.exactInput,
          ),
        )
        .toList(growable: false);
    state = state.copyWith(
      splitMethod: method,
      memberSplits: updatedMembers,
      exactSplitError: null,
      submissionError: null,
    );
    if (method == SplitMethod.equal) {
      _recalculateEqualSplits();
    } else {
      _validateExactSplits();
    }
  }

  void selectGroup(String? groupId) {
    if (groupId == state.selectedGroupId) {
      return;
    }
    final group = state.groups.firstWhereOrNull((item) => item.id == groupId);
    final members = group?.members ?? const <GroupMemberOption>[];
    final payerId =
        members
            .firstWhereOrNull((member) => member.id == currentUserMemberId)
            ?.id ??
        (members.isEmpty ? null : members.first.id);

    state = state.copyWith(
      selectedGroupId: groupId,
      selectedPayerId: payerId,
      memberSplits: members
          .map(
            (member) =>
                MemberSplitState(memberId: member.id, memberName: member.name),
          )
          .toList(growable: false),
      exactSplitError: null,
      submissionError: null,
    );

    if (state.splitMethod == SplitMethod.equal) {
      _recalculateEqualSplits();
    } else {
      _validateExactSplits();
    }
  }

  void selectAccount(String? accountId) {
    state = state.copyWith(selectedAccountId: accountId, submissionError: null);
  }

  void updateAmount(String value) {
    final parsed = _parseAmountToPaise(value);
    state = state.copyWith(
      amountInput: value,
      amountPaise: parsed,
      submissionError: null,
    );
    if (state.kind == ExpenseKind.split &&
        state.splitMethod == SplitMethod.equal) {
      _recalculateEqualSplits();
    } else if (state.kind == ExpenseKind.split &&
        state.splitMethod == SplitMethod.exact) {
      _validateExactSplits();
    }
  }

  void updateDescription(String value) {
    state = state.copyWith(description: value, submissionError: null);
  }

  void updateCategory(String value) {
    state = state.copyWith(category: value, submissionError: null);
  }

  void updateNotes(String value) {
    state = state.copyWith(notes: value, submissionError: null);
  }

  void selectPayer(String? memberId) {
    state = state.copyWith(selectedPayerId: memberId, submissionError: null);
  }

  void updateDate(DateTime date) {
    state = state.copyWith(date: date, submissionError: null);
  }

  void updateExactShare(String memberId, String value) {
    final members = state.memberSplits
        .map((member) {
          if (member.memberId != memberId) {
            return member;
          }
          final parsed = _parseAmountToPaise(value);
          return member.copyWith(exactInput: value, sharePaise: parsed ?? 0);
        })
        .toList(growable: false);
    state = state.copyWith(memberSplits: members, submissionError: null);
    _validateExactSplits();
  }

  Future<bool> submit() async {
    final validationState = state.copyWith(hasTriedSubmit: true);
    state = validationState.copyWith(submissionError: null);

    if (!_isFormValid(validationState)) {
      if (validationState.isExactMode) {
        _validateExactSplits();
      }
      return false;
    }

    final draft = _buildDraft(validationState);
    state = validationState.copyWith(isSaving: true, submissionError: null);

    try {
      await repository.createExpense(draft);
      state = validationState.copyWith(isSaving: false);
      return true;
    } catch (error) {
      state = validationState.copyWith(
        isSaving: false,
        submissionError: "Couldn't save. Retry.",
      );
      return false;
    }
  }

  ExpenseDraft _buildDraft(NewExpenseState snapshot) {
    final groupId = snapshot.selectedGroupId ?? '';
    final amountPaise = snapshot.amountPaise ?? 0;
    final notesValue = snapshot.notes.trim().isEmpty
        ? null
        : snapshot.notes.trim();
    final splits = _buildSplits(snapshot, amountPaise);

    return ExpenseDraft(
      groupId: groupId,
      title: snapshot.description.trim(),
      amountPaise: amountPaise,
      category: snapshot.category.trim(),
      paidByMemberId: snapshot.selectedPayerId ?? currentUserMemberId,
      date: DateTime(
        snapshot.date.year,
        snapshot.date.month,
        snapshot.date.day,
      ),
      accountId:
          snapshot.selectedAccountId ?? AccountRepository.defaultAccountId,
      notes: notesValue,
      splits: splits,
    );
  }

  List<ExpenseSplitShareInput> _buildSplits(
    NewExpenseState snapshot,
    int amountPaise,
  ) {
    if (snapshot.kind == ExpenseKind.individual) {
      final payerId = snapshot.selectedPayerId ?? currentUserMemberId;
      return [
        ExpenseSplitShareInput(memberId: payerId, sharePaise: amountPaise),
      ];
    }

    return snapshot.memberSplits
        .map(
          (member) => ExpenseSplitShareInput(
            memberId: member.memberId,
            sharePaise: member.sharePaise,
          ),
        )
        .toList(growable: false);
  }

  bool _isFormValid(NewExpenseState snapshot) {
    if (snapshot.hasAmountError) {
      return false;
    }
    if (snapshot.kind == ExpenseKind.split && snapshot.hasGroupError) {
      return false;
    }
    if (snapshot.hasPayerError) {
      return false;
    }
    if (snapshot.description.trim().isEmpty) {
      return false;
    }
    if (snapshot.category.trim().isEmpty) {
      return false;
    }
    if (snapshot.kind == ExpenseKind.split && snapshot.isExactMode) {
      final error = _validateExactSplits();
      if (error != null) {
        return false;
      }
    }
    return true;
  }

  int? _parseAmountToPaise(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final normalized = trimmed.replaceAll(',', '');
    final negative = normalized.startsWith('-');
    final cleaned = negative ? normalized.substring(1) : normalized;
    final parts = cleaned.split('.');
    if (parts.length > 2) {
      return null;
    }
    final rupeesPart = parts.first;
    if (rupeesPart.isEmpty) {
      return null;
    }
    final rupees = int.tryParse(rupeesPart);
    if (rupees == null) {
      return null;
    }
    var paise = 0;
    if (parts.length == 2) {
      final fraction = parts[1];
      if (fraction.length > 2) {
        return null;
      }
      final fractionValue = fraction.padRight(2, '0');
      final parsedFraction = int.tryParse(fractionValue);
      if (parsedFraction == null) {
        return null;
      }
      paise = parsedFraction;
    }
    final total = rupees * 100 + paise;
    return negative ? -total : total;
  }

  String _formatPaiseAsInput(int paise) {
    final isNegative = paise.isNegative;
    final absolute = paise.abs();
    final rupees = absolute ~/ 100;
    final remainder = absolute % 100;
    final buffer = StringBuffer();
    if (isNegative) {
      buffer.write('-');
    }
    buffer.write(rupees);
    if (remainder != 0) {
      buffer.write('.');
      if (remainder % 10 == 0) {
        buffer.write((remainder ~/ 10).toString());
      } else {
        buffer.write(remainder.toString().padLeft(2, '0'));
      }
    }
    return buffer.toString();
  }

  void _recalculateEqualSplits() {
    if (state.memberSplits.isEmpty) {
      return;
    }
    final amount = state.amountPaise ?? 0;
    final members = state.memberSplits;
    if (amount <= 0) {
      final reset = members
          .map((member) => member.copyWith(sharePaise: 0))
          .toList(growable: false);
      state = state.copyWith(memberSplits: reset, exactSplitError: null);
      return;
    }

    final base = amount ~/ members.length;
    var remainder = amount % members.length;
    final updated = <MemberSplitState>[];
    for (final member in members) {
      final extra = remainder > 0 ? 1 : 0;
      if (remainder > 0) {
        remainder -= 1;
      }
      final share = base + extra;
      updated.add(
        member.copyWith(
          sharePaise: share,
          exactInput: state.isExactMode
              ? _formatPaiseAsInput(share)
              : member.exactInput,
        ),
      );
    }
    state = state.copyWith(memberSplits: updated, exactSplitError: null);
  }

  String? _validateExactSplits() {
    if (state.memberSplits.isEmpty) {
      state = state.copyWith(exactSplitError: null);
      return null;
    }
    final amount = state.amountPaise ?? 0;
    final total = state.memberSplits.fold<int>(
      0,
      (sum, member) => sum + member.sharePaise,
    );
    if (amount == 0 || total == amount) {
      state = state.copyWith(exactSplitError: null);
      return null;
    }
    final message = 'Exact split must equal ${state.amountDisplay}';
    state = state.copyWith(exactSplitError: message);
    return message;
  }
}

final newExpenseFormDataProvider = Provider<ExpenseFormData>((ref) {
  throw UnimplementedError('Form data must be overridden in the widget scope.');
});

final newExpenseControllerProvider =
    StateNotifierProvider.autoDispose<NewExpenseController, NewExpenseState>((
      ref,
    ) {
      final formData = ref.watch(newExpenseFormDataProvider);
      final repository = ref.watch(expenseRepositoryProvider);
      return NewExpenseController(repository: repository, formData: formData);
    });
