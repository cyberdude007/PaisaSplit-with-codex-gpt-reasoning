import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters/currency_formatter.dart';
import '../../../core/formatters/date_utils.dart';
import '../../expenses/data/expense_models.dart';
import '../data/settle_models.dart';
import '../data/settle_repository.dart';

class SettleUpScreen extends ConsumerWidget {
  const SettleUpScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(groupBalancesProvider(groupId));
    final historyAsync = ref.watch(settlementHistoryProvider(groupId));

    return Scaffold(
      appBar: AppBar(
        title: balancesAsync.when(
          data: (summary) => Text('Settle Up • ${summary.groupName}'),
          loading: () => const Text('Settle Up'),
          error: (_, __) => const Text('Settle Up'),
        ),
      ),
      body: balancesAsync.when(
        data: (summary) => _SettleUpBody(
          groupId: groupId,
          summary: summary,
          historyAsync: historyAsync,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(message: error.toString()),
      ),
    );
  }
}

class _SettleUpBody extends ConsumerWidget {
  const _SettleUpBody({
    required this.groupId,
    required this.summary,
    required this.historyAsync,
  });

  final String groupId;
  final GroupBalanceSummary summary;
  final AsyncValue<List<SettlementHistoryEntry>> historyAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserBalance = summary.currentUserBalance;
    final hasBalance =
        currentUserBalance != null && currentUserBalance.netBalancePaise != 0;
    final eligibleCounterparties = summary.otherMemberBalances.where((member) {
      if (member.isSettled) {
        return false;
      }
      if (currentUserBalance == null || currentUserBalance.isSettled) {
        return false;
      }
      return currentUserBalance.netBalancePaise.isNegative
          ? member.isCreditor
          : member.isDebtor;
    }).toList(growable: false);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      children: [
        Text('Counterparties', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (!hasBalance)
          const _InfoCard(
            title: 'All Settled',
            subtitle: 'No outstanding balances for you in this group.',
          )
        else if (eligibleCounterparties.isEmpty)
          const _InfoCard(
            title: 'No Counterparties',
            subtitle:
                'Members owing or owed to you will appear here once expenses are added.',
          )
        else
          ...eligibleCounterparties.map(
            (member) => _CounterpartyTile(
              groupId: groupId,
              summary: summary,
              member: member,
            ),
          ),
        const SizedBox(height: 24),
        Text('History', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        historyAsync.when(
          data: (entries) {
            if (entries.isEmpty) {
              return const _InfoCard(
                title: 'No settlements yet',
                subtitle: 'Manual settlements you record will be listed here.',
              );
            }
            return Column(
              children: [
                for (final entry in entries) _HistoryTile(entry: entry),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(message: error.toString()),
        ),
      ],
    );
  }
}

class _CounterpartyTile extends ConsumerWidget {
  const _CounterpartyTile({
    required this.groupId,
    required this.summary,
    required this.member,
  });

  final String groupId;
  final GroupBalanceSummary summary;
  final MemberBalance member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserBalance = summary.currentUserBalance;
    if (currentUserBalance == null || currentUserBalance.isSettled) {
      return const SizedBox.shrink();
    }

    final isYouPaying = currentUserBalance.netBalancePaise.isNegative;
    final contextText = isYouPaying
        ? 'You pay ${member.memberName}'
        : '${member.memberName} pays you';
    final absoluteCounterparty = member.netBalancePaise.abs();
    final absoluteYou = currentUserBalance.netBalancePaise.abs();
    final suggestedAmount = min(absoluteCounterparty, absoluteYou);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(child: Text(_initialFor(member.memberName))),
        title: Text(member.memberName),
        subtitle: Text(contextText),
        trailing: Text(formatCurrencyFromPaise(suggestedAmount)),
        onTap: () => _openManualSettlementSheet(
          context,
          ref,
          groupId: groupId,
          member: member,
          suggestedAmount: suggestedAmount,
          isYouPaying: isYouPaying,
        ),
      ),
    );
  }
}

Future<void> _openManualSettlementSheet(
  BuildContext context,
  WidgetRef ref, {
  required String groupId,
  required MemberBalance member,
  required int suggestedAmount,
  required bool isYouPaying,
}) async {
  final result = await showModalBottomSheet<_SettlementInputResult>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _ManualSettlementSheet(
      member: member,
      suggestedAmountPaise: suggestedAmount,
      isYouPaying: isYouPaying,
    ),
  );
  if (result == null) {
    return;
  }

  if (!context.mounted) {
    return;
  }

  final formattedAmount = formatCurrencyFromPaise(result.amountPaise);
  final dateLabel = formatDisplayDate(result.date);
  final directionText = isYouPaying
      ? 'You will pay ${member.memberName}'
      : '${member.memberName} will pay you';

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirm Settlement'),
      content: Text(
        '$directionText\nAmount: $formattedAmount\nDate: $dateLabel',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Confirm'),
        ),
      ],
    ),
  );

  if (confirmed != true) {
    return;
  }

  final fromMemberId = isYouPaying ? currentUserMemberId : member.memberId;
  final toMemberId = isYouPaying ? member.memberId : currentUserMemberId;

  final repository = ref.read(settleRepositoryProvider);
  if (!context.mounted) {
    return;
  }
  final messenger = ScaffoldMessenger.of(context);

  try {
    await repository.recordManualSettlement(
      groupId: groupId,
      fromMemberId: fromMemberId,
      toMemberId: toMemberId,
      amountPaise: result.amountPaise,
      date: result.date,
      note: result.note,
    );
    messenger.showSnackBar(
      SnackBar(content: Text('Settlement recorded: $formattedAmount')),
    );
  } catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text('Failed to record settlement: $error')),
    );
  }
}

class _ManualSettlementSheet extends StatefulWidget {
  const _ManualSettlementSheet({
    required this.member,
    required this.suggestedAmountPaise,
    required this.isYouPaying,
  });

  final MemberBalance member;
  final int suggestedAmountPaise;
  final bool isYouPaying;

  @override
  State<_ManualSettlementSheet> createState() => _ManualSettlementSheetState();
}

class _ManualSettlementSheetState extends State<_ManualSettlementSheet> {
  late final TextEditingController _amountController;
  final TextEditingController _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: (widget.suggestedAmountPaise / 100).toStringAsFixed(2),
    );
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomInset,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isYouPaying
                  ? 'You pay ${widget.member.memberName}'
                  : '${widget.member.memberName} pays you',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                hintText: '0.00',
              ),
              validator: (value) {
                final amount = _parseAmount(value);
                if (amount == null || amount <= 0) {
                  return 'Enter a valid amount';
                }
                if (amount > widget.suggestedAmountPaise) {
                  return 'Cannot exceed outstanding amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Date: ${formatDisplayDate(_selectedDate)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                TextButton(
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(now.year - 5),
                      lastDate: DateTime(now.year + 5),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                      });
                    }
                  },
                  child: const Text('Change'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }
                  final amountPaise = _parseAmount(_amountController.text) ?? 0;
                  Navigator.of(context).pop(
                    _SettlementInputResult(
                      amountPaise: amountPaise,
                      date: _selectedDate,
                      note: _noteController.text.trim().isEmpty
                          ? null
                          : _noteController.text.trim(),
                    ),
                  );
                },
                child: const Text('Record Settlement'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  int? _parseAmount(String? raw) {
    if (raw == null) {
      return null;
    }
    final sanitized = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    if (sanitized.isEmpty) {
      return null;
    }
    final parsed = double.tryParse(sanitized);
    if (parsed == null) {
      return null;
    }
    return (parsed * 100).round();
  }
}

class _SettlementInputResult {
  const _SettlementInputResult({
    required this.amountPaise,
    required this.date,
    this.note,
  });

  final int amountPaise;
  final DateTime date;
  final String? note;
}

String _initialFor(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return '?';
  }
  return trimmed.substring(0, 1).toUpperCase();
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry});

  final SettlementHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final amountLabel = formatCurrencyFromPaise(entry.amountPaise);
    final dateLabel = formatDisplayDate(entry.date);

    final directionText = entry.toMemberId == currentUserMemberId
        ? '${entry.fromMemberName} → You'
        : 'You → ${entry.toMemberName}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.history),
        title: Text(directionText),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateLabel),
            if (entry.note != null && entry.note!.isNotEmpty) Text(entry.note!),
          ],
        ),
        trailing: Text(amountLabel),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(subtitle),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
