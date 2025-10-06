import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters/currency_formatter.dart';
import '../../../core/formatters/date_utils.dart';
import '../data/expense_repository.dart';
import 'new_expense_controller.dart';

class NewExpenseScreen extends ConsumerWidget {
  const NewExpenseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formDataAsync = ref.watch(expenseFormDataProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Expense')),
      body: formDataAsync.when(
        data: (formData) => ProviderScope(
          overrides: [newExpenseFormDataProvider.overrideWithValue(formData)],
          child: const _NewExpenseForm(),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            const Center(child: Text('Unable to load expense form.')),
      ),
    );
  }
}

class _NewExpenseForm extends ConsumerStatefulWidget {
  const _NewExpenseForm();

  @override
  ConsumerState<_NewExpenseForm> createState() => _NewExpenseFormState();
}

class _NewExpenseFormState extends ConsumerState<_NewExpenseForm> {
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  late final TextEditingController _notesController;
  final Map<String, TextEditingController> _exactControllers = {};

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
    _categoryController = TextEditingController();
    _notesController = TextEditingController();

    ref.listen<NewExpenseState>(
      newExpenseControllerProvider,
      (previous, next) => _syncControllers(next),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncControllers(ref.read(newExpenseControllerProvider));
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _notesController.dispose();
    for (final controller in _exactControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncControllers(NewExpenseState state) {
    if (_amountController.text != state.amountInput) {
      _amountController.value = TextEditingValue(
        text: state.amountInput,
        selection: TextSelection.collapsed(offset: state.amountInput.length),
      );
    }
    if (_descriptionController.text != state.description) {
      _descriptionController.value = TextEditingValue(
        text: state.description,
        selection: TextSelection.collapsed(offset: state.description.length),
      );
    }
    if (_categoryController.text != state.category) {
      _categoryController.value = TextEditingValue(
        text: state.category,
        selection: TextSelection.collapsed(offset: state.category.length),
      );
    }
    if (_notesController.text != state.notes) {
      _notesController.value = TextEditingValue(
        text: state.notes,
        selection: TextSelection.collapsed(offset: state.notes.length),
      );
    }

    final existingKeys = _exactControllers.keys.toSet();
    final nextKeys =
        state.memberSplits.map((member) => member.memberId).toSet();

    for (final key in existingKeys.difference(nextKeys)) {
      _exactControllers.remove(key)?.dispose();
    }

    for (final member in state.memberSplits) {
      final controller = _exactControllers.putIfAbsent(
        member.memberId,
        () => TextEditingController(),
      );
      if (controller.text != member.exactInput) {
        controller.value = TextEditingValue(
          text: member.exactInput,
          selection: TextSelection.collapsed(offset: member.exactInput.length),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(newExpenseControllerProvider);
    final controller = ref.read(newExpenseControllerProvider.notifier);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _KindSelector(
                  selected: state.kind,
                  onSelected: controller.switchKind,
                ),
                const SizedBox(height: 24),
                _AmountField(
                  controller: _amountController,
                  hasError: state.hasTriedSubmit && state.hasAmountError,
                  onChanged: controller.updateAmount,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  onChanged: controller.updateDescription,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    errorText:
                        state.hasTriedSubmit && state.description.trim().isEmpty
                            ? 'Enter a description'
                            : null,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _categoryController,
                  onChanged: controller.updateCategory,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    errorText:
                        state.hasTriedSubmit && state.category.trim().isEmpty
                            ? 'Enter a category'
                            : null,
                  ),
                ),
                const SizedBox(height: 16),
                _GroupDropdown(state: state, onChanged: controller.selectGroup),
                const SizedBox(height: 16),
                _AccountDropdown(
                  state: state,
                  onChanged: controller.selectAccount,
                ),
                const SizedBox(height: 16),
                _PaidByChips(state: state, onSelected: controller.selectPayer),
                const SizedBox(height: 16),
                _DatePickerTile(
                  date: state.date,
                  onPick: (picked) => controller.updateDate(picked),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  onChanged: controller.updateNotes,
                  textInputAction: TextInputAction.newline,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
                if (state.kind == ExpenseKind.split) ...[
                  const SizedBox(height: 24),
                  _SplitMethodSelector(
                    selected: state.splitMethod,
                    onSelected: controller.selectSplitMethod,
                  ),
                  const SizedBox(height: 16),
                  if (state.splitMethod == SplitMethod.equal)
                    _EqualSplitSummary(memberSplits: state.memberSplits)
                  else
                    _ExactSplitEditor(
                      state: state,
                      controllers: _exactControllers,
                      onChanged: controller.updateExactShare,
                    ),
                  if (state.exactSplitError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      state.exactSplitError!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                  ],
                  if (state.hasTriedSubmit && state.hasGroupError) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Select a group',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                  ],
                ] else ...[
                  const SizedBox(height: 16),
                  // ignore: todo
                  // TODO(PRD Clarification): confirm whether the group selector
                  // should be hidden for individual expenses.
                ],
                if (state.hasTriedSubmit && state.hasPayerError) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Select who paid',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ],
                if (state.submissionError != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    state.submissionError!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
        _NewExpenseFooter(
          isSaving: state.isSaving,
          kind: state.kind,
          onPressed: () async {
            FocusScope.of(context).unfocus();
            final messenger = ScaffoldMessenger.of(context);
            final navigator = Navigator.of(context);
            final success = await controller.submit();
            if (!mounted) {
              return;
            }
            if (success) {
              messenger.showSnackBar(
                const SnackBar(content: Text('Expense saved.')),
              );
              navigator.pop(true);
            }
          },
        ),
      ],
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.hasError,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool hasError;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: 'Amount (₹)',
        errorText: hasError ? 'Enter an amount greater than zero' : null,
      ),
    );
  }
}

class _KindSelector extends StatelessWidget {
  const _KindSelector({required this.selected, required this.onSelected});

  final ExpenseKind selected;
  final ValueChanged<ExpenseKind> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.secondary;

    Widget buildCard(ExpenseKind kind, String label, IconData icon) {
      final isSelected = selected == kind;
      return Expanded(
        child: Card(
          color: isSelected
              ? color.withValues(alpha: 0.16)
              : theme.colorScheme.surface,
          elevation: isSelected ? 2 : 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onSelected(kind),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: isSelected ? color : theme.iconTheme.color),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isSelected
                          ? color
                          : theme.textTheme.titleMedium?.color,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        buildCard(ExpenseKind.split, 'Split', Icons.groups),
        const SizedBox(width: 12),
        buildCard(ExpenseKind.individual, 'Individual', Icons.person),
      ],
    );
  }
}

class _GroupDropdown extends StatelessWidget {
  const _GroupDropdown({required this.state, required this.onChanged});

  final NewExpenseState state;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (state.groups.isEmpty) {
      return Text(
        'No groups available',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return InputDecorator(
      decoration: const InputDecoration(labelText: 'Group'),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: state.selectedGroupId,
          isExpanded: true,
          onChanged: onChanged,
          items: state.groups
              .map(
                (group) => DropdownMenuItem<String>(
                  value: group.id,
                  child: Text(group.name),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _AccountDropdown extends StatelessWidget {
  const _AccountDropdown({required this.state, required this.onChanged});

  final NewExpenseState state;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(labelText: 'Payment Account'),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: state.selectedAccountId,
          isExpanded: true,
          onChanged: onChanged,
          items: state.accounts
              .map(
                (account) => DropdownMenuItem<String>(
                  value: account.id,
                  child: Text(account.name),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _PaidByChips extends StatelessWidget {
  const _PaidByChips({required this.state, required this.onSelected});

  final NewExpenseState state;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (state.memberSplits.isEmpty) {
      return Text(
        'No members in group',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Paid By', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: state.memberSplits
              .map(
                (member) => ChoiceChip(
                  label: Text(member.memberName),
                  selected: state.selectedPayerId == member.memberId,
                  onSelected: (_) => onSelected(member.memberId),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({required this.date, required this.onPick});

  final DateTime date;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Date'),
      subtitle: Text(formatDisplayDate(date)),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(now.year - 5),
          lastDate: DateTime(now.year + 5),
        );
        if (picked != null) {
          onPick(picked);
        }
      },
    );
  }
}

class _SplitMethodSelector extends StatelessWidget {
  const _SplitMethodSelector({
    required this.selected,
    required this.onSelected,
  });

  final SplitMethod selected;
  final ValueChanged<SplitMethod> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.secondary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: SplitMethod.values.map((method) {
        final isSelected = selected == method;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: OutlinedButton(
              onPressed: () => onSelected(method),
              style: OutlinedButton.styleFrom(
                backgroundColor:
                    isSelected ? color.withValues(alpha: 0.16) : null,
              ),
              child: Text(
                method == SplitMethod.equal ? 'Equally' : 'Exact',
                style: theme.textTheme.titleMedium?.copyWith(
                  color:
                      isSelected ? color : theme.textTheme.titleMedium?.color,
                ),
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _EqualSplitSummary extends StatelessWidget {
  const _EqualSplitSummary({required this.memberSplits});

  final List<MemberSplitState> memberSplits;

  @override
  Widget build(BuildContext context) {
    if (memberSplits.isEmpty) {
      return Text(
        'No members to split',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: memberSplits
          .map(
            (member) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    member.memberName,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(formatCurrencyFromPaise(member.sharePaise)),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _ExactSplitEditor extends StatelessWidget {
  const _ExactSplitEditor({
    required this.state,
    required this.controllers,
    required this.onChanged,
  });

  final NewExpenseState state;
  final Map<String, TextEditingController> controllers;
  final void Function(String memberId, String value) onChanged;

  @override
  Widget build(BuildContext context) {
    if (state.memberSplits.isEmpty) {
      return Text(
        'No members to split',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return Column(
      children: state.memberSplits
          .map(
            (member) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      member.memberName,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: controllers[member.memberId],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: false,
                      ),
                      onChanged: (value) => onChanged(member.memberId, value),
                      decoration: const InputDecoration(labelText: 'Share (₹)'),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _NewExpenseFooter extends StatelessWidget {
  const _NewExpenseFooter({
    required this.isSaving,
    required this.kind,
    required this.onPressed,
  });

  final bool isSaving;
  final ExpenseKind kind;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final buttonLabel =
        kind == ExpenseKind.split ? 'Save Split' : 'Save Individual';
    return SafeArea(
      minimum: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isSaving ? null : onPressed,
          child: isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(buttonLabel),
        ),
      ),
    );
  }
}
