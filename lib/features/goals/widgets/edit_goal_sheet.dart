import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sms_transaction_app/core/tokens.dart';
import 'package:sms_transaction_app/data/models/goal.dart';
import 'package:sms_transaction_app/services/providers.dart';

/// Bottom sheet for editing an existing savings goal's name, description,
/// target amount, and deadline. Mirrors [CreateGoalSheet] but pre-fills from
/// the passed-in [goal] and persists via `updateGoal` (preserving id, current
/// amount, icon, and active flag).
class EditGoalSheet extends ConsumerStatefulWidget {
  const EditGoalSheet({super.key, required this.goal});

  final Goal goal;

  @override
  ConsumerState<EditGoalSheet> createState() => _EditGoalSheetState();
}

class _EditGoalSheetState extends ConsumerState<EditGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _targetController;
  late final TextEditingController _descriptionController;
  late DateTime _selectedDeadline;

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    _nameController = TextEditingController(text: g.name);
    _targetController = TextEditingController(
      text: g.targetAmount == g.targetAmount.roundToDouble()
          ? g.targetAmount.toInt().toString()
          : g.targetAmount.toString(),
    );
    _descriptionController = TextEditingController(text: g.description);
    _selectedDeadline = g.deadline;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline.isBefore(DateTime.now())
          ? DateTime.now()
          : _selectedDeadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (picked != null) {
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    final db = ref.read(databaseHelperProvider);

    // Preserve everything not editable here (id, currentAmount, icon, active).
    final updated = widget.goal.copyWith(
      name: _nameController.text,
      description: _descriptionController.text,
      targetAmount: double.parse(_targetController.text),
      deadline: _selectedDeadline,
    );

    await db.updateGoal(updated.id, updated.toMap());
    ref.invalidate(goalsProvider);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.theming;
    final theme = Theme.of(context);
    const accent = AppColors.violet;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
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
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadii.m),
                    ),
                    child: const Icon(Icons.edit, color: accent),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Text(
                      'Edit Savings Goal',
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

              // Goal Name
              Text(
                'Goal Name',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.s),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Emergency Fund',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a goal name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.l),

              // Description
              Text(
                'Description',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.s),
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'What is this goal for?',
                ),
              ),
              const SizedBox(height: AppSpacing.l),

              // Target Amount
              Text(
                'Target Amount',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.s),
              TextFormField(
                controller: _targetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: '0',
                  prefixText: 'ETB ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a target amount';
                  }
                  final parsed = double.tryParse(value);
                  if (parsed == null) {
                    return 'Please enter a valid number';
                  }
                  if (parsed < widget.goal.currentAmount) {
                    return 'Target can\'t be less than saved '
                        '(${widget.goal.currentAmount.toStringAsFixed(0)})';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.l),

              // Deadline
              Text(
                'Target Date',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.s),
              InkWell(
                onTap: _selectDeadline,
                borderRadius: BorderRadius.circular(AppRadii.m),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  decoration: BoxDecoration(
                    border: Border.all(color: t.border),
                    borderRadius: BorderRadius.circular(AppRadii.m),
                    color: t.surfaceElevated,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: t.textSecondary),
                      const SizedBox(width: AppSpacing.m),
                      Text(
                        DateFormat('MMM dd, yyyy').format(_selectedDeadline),
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saveGoal,
                  child: const Text('Save Changes'),
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
