import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/formatting.dart';
import '../../data/models/trip.dart';

class ExpenseDraft {
  const ExpenseDraft({
    required this.title,
    required this.note,
    required this.amount,
    required this.category,
    required this.date,
  });

  final String title;
  final String note;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
}

/// Form used to add or edit one trip expense.
class ExpenseSheet extends StatefulWidget {
  const ExpenseSheet({super.key, required this.currency, this.existing});

  final String currency;
  final Expense? existing;

  @override
  State<ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends State<ExpenseSheet> {
  late final TextEditingController _title = TextEditingController(
    text: widget.existing?.title ?? '',
  );
  late final TextEditingController _note = TextEditingController(
    text: widget.existing?.note ?? '',
  );
  late final TextEditingController _amount = TextEditingController(
    text: widget.existing == null ? '' : Fmt.smart(widget.existing!.amount),
  );
  late ExpenseCategory _category =
      widget.existing?.category ?? ExpenseCategory.food;
  late DateTime _date = widget.existing?.date ?? DateTime.now();

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _date = DateTime(picked.year, picked.month, picked.day, 12);
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final L10n l10n = L10n.of(context);
    final bool editing = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  editing ? l10n.editExpense : l10n.addExpense,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  key: const Key('expense-what-for'),
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(labelText: l10n.whatFor),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('expense-amount'),
                  controller: _amount,
                  autofocus: !editing,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: l10n.amountLabel,
                    suffixText: widget.currency,
                  ),
                ),
                const SizedBox(height: 12),
                Material(
                  color: p.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    key: const Key('expense-date'),
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.event, size: 18, color: p.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.spendingDate,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: p.textSecondary,
                              ),
                            ),
                          ),
                          Text(
                            Fmt.date(_date),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: p.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.category,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: p.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ExpenseCategory.values.map((ExpenseCategory c) {
                    final bool selected = c == _category;
                    return ChoiceChip(
                      label: Text(_chipLabel(l10n, c)),
                      selected: selected,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _category = c),
                      labelStyle: TextStyle(
                        fontSize: 11.5,
                        color: selected ? p.onPrimary : p.textPrimary,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('expense-note'),
                  controller: _note,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l10n.expenseNote,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    final double? value = Fmt.parse(_amount.text);
                    if (value == null) return;
                    Navigator.of(context).pop(
                      ExpenseDraft(
                        title: _title.text,
                        note: _note.text,
                        amount: value,
                        category: _category,
                        date: _date,
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Text(l10n.saveExpense),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _chipLabel(L10n l10n, ExpenseCategory category) {
  switch (category) {
    case ExpenseCategory.food:
      return l10n.catFood;
    case ExpenseCategory.transport:
      return l10n.catTransport;
    case ExpenseCategory.hotel:
      return l10n.catHotel;
    case ExpenseCategory.shopping:
      return l10n.catShopping;
    case ExpenseCategory.sightseeing:
      return l10n.catSightseeing;
    case ExpenseCategory.other:
      return l10n.catOther;
  }
}
