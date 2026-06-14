import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sms_transaction_app/core/tokens.dart';
import 'package:sms_transaction_app/data/models/budget.dart';
import 'package:sms_transaction_app/services/providers.dart';

class EditBudgetSheet extends ConsumerStatefulWidget {
  final Budget budget;

  const EditBudgetSheet({super.key, required this.budget});

  @override
  ConsumerState<EditBudgetSheet> createState() => _EditBudgetSheetState();
}

class _EditBudgetSheetState extends ConsumerState<EditBudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _limitController;

  late String _selectedCategory;
  late String _selectedPeriod;

  final List<String> _categories = [
    'Food & Dining',
    'Transportation',
    'Entertainment',
    'Shopping',
    'Utilities',
    'Healthcare',
    'Transfer',
    'Other',
  ];

  final List<String> _periods = ['Weekly', 'Monthly', 'Yearly'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.budget.name);
    _limitController = TextEditingController(text: widget.budget.limit.toStringAsFixed(0));
    _selectedCategory = widget.budget.category;
    _selectedPeriod = widget.budget.period.substring(0, 1).toUpperCase() + widget.budget.period.substring(1);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _updateBudget() async {
    if (_formKey.currentState!.validate()) {
      final db = ref.read(databaseHelperProvider);

      // Update budget in database
      final updatedBudget = {
        'name': _nameController.text,
        'category': _selectedCategory,
        'limit_amount': double.parse(_limitController.text),
        'period': _selectedPeriod.toLowerCase(),
        'start_date': widget.budget.startDate.toIso8601String(),
        'end_date': widget.budget.endDate.toIso8601String(),
        'is_active': widget.budget.isActive ? 1 : 0,
      };

      await db.updateBudget(widget.budget.id, updatedBudget);

      // Refresh budgets provider
      ref.invalidate(budgetsProvider);

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.theming;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(AppRadii.m),
                    ),
                    child: const Icon(Icons.edit, color: AppColors.accent),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Text(
                      'Edit Budget',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Budget Name
              Text(
                'Budget Name',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.s),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Monthly Food Budget',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a budget name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.l),

              // Category
              Text(
                'Category',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.s),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.l),

              // Budget Limit
              Text(
                'Budget Limit',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.s),
              TextFormField(
                controller: _limitController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: '0',
                  prefixText: 'ETB ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a budget limit';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.l),

              // Period
              Text(
                'Period',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.s),
              DropdownButtonFormField<String>(
                value: _selectedPeriod,
                items: _periods.map((period) {
                  return DropdownMenuItem(
                    value: period,
                    child: Text(period),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPeriod = value!;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Update Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _updateBudget,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
                  ),
                  child: const Text(
                    'Update Budget',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s),
            ],
          ),
        ),
      ),
    );
  }
}
