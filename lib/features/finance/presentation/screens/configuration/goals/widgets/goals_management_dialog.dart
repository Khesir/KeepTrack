import 'package:flutter/material.dart';

import '../../../../../modules/goal/domain/entities/goal.dart';

class GoalsManagementDialog extends StatefulWidget {
  final Goal? goal;
  final String userId;
  final Function(Goal) onSave;

  const GoalsManagementDialog({
    this.goal,
    required this.userId,
    required this.onSave,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _GoalsManagementScreenState();
}

class _GoalsManagementScreenState extends State<GoalsManagementDialog> {
  late final TextEditingController nameController;
  late final TextEditingController descriptionController;
  late final TextEditingController targetAmountController;
  late final TextEditingController currentAmountController;
  late final TextEditingController monthlyContributionController;

  late DateTime? selectedTargetDate;
  late GoalStatus selectedStatus;
  late Color selectedColor;

  bool get isEdit => widget.goal != null;

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    nameController = TextEditingController(text: g?.name ?? '');
    descriptionController = TextEditingController(text: g?.description ?? '');
    targetAmountController = TextEditingController(
      text: g?.targetAmount.toString() ?? '',
    );
    currentAmountController = TextEditingController(
      text: g?.currentAmount.toString() ?? '0',
    );
    monthlyContributionController = TextEditingController(
      text: g?.monthlyContribution.toString() ?? '0',
    );

    selectedTargetDate = g?.targetDate;
    selectedStatus = g?.status ?? GoalStatus.active;
    selectedColor = g?.colorHex != null
        ? Color(int.parse(g!.colorHex!.replaceFirst('#', '0xFF')))
        : Colors.blue;
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    targetAmountController.dispose();
    currentAmountController.dispose();
    monthlyContributionController.dispose();
    super.dispose();
  }

  void _saveGoal() {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a goal name')));
      return;
    }
    if (targetAmountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a target amount')),
      );
      return;
    }

    final targetAmount = double.tryParse(targetAmountController.text) ?? 0;
    final currentAmount = double.tryParse(currentAmountController.text) ?? 0;
    final monthlyContribution =
        double.tryParse(monthlyContributionController.text) ?? 0;

    final colorHex = '#${selectedColor.value.toRadixString(16).substring(2)}';

    final goalEntity = Goal(
      id: widget.goal?.id,
      name: nameController.text.trim(),
      description: descriptionController.text.trim(),
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      targetDate: selectedTargetDate,
      colorHex: colorHex,
      status: selectedStatus,
      monthlyContribution: monthlyContribution,
      userId: widget.userId,
    );

    widget.onSave(goalEntity);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isEdit ? 'Goal updated' : 'Goal created')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(isEdit ? 'Edit Goal' : 'Create Goal'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Goal Name',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Emergency Fund, New Car',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  hintText: 'What is this goal for?',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: targetAmountController,
                decoration: const InputDecoration(
                  labelText: 'Target Amount',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: currentAmountController,
                decoration: const InputDecoration(
                  labelText: 'Current Amount',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: monthlyContributionController,
                decoration: const InputDecoration(
                  labelText: 'Monthly Contribution',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Target Date'),
                subtitle: Text(
                  selectedTargetDate != null
                      ? '${selectedTargetDate?.year}-${selectedTargetDate?.month.toString().padLeft(2, '0')}-${selectedTargetDate?.day.toString().padLeft(2, '0')}'
                      : 'No target date set',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedTargetDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (date != null) {
                      setDialogState(() {
                        selectedTargetDate = date;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Goal Status',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SegmentedButton<GoalStatus>(
                segments: const [
                  ButtonSegment(
                    value: GoalStatus.active,
                    label: Text('Active'),
                    icon: Icon(Icons.play_arrow),
                  ),
                  ButtonSegment(
                    value: GoalStatus.paused,
                    label: Text('Paused'),
                    icon: Icon(Icons.pause),
                  ),
                  ButtonSegment(
                    value: GoalStatus.completed,
                    label: Text('Completed'),
                    icon: Icon(Icons.check),
                  ),
                ],
                selected: {selectedStatus},
                onSelectionChanged: (Set<GoalStatus> newSelection) {
                  setDialogState(() {
                    selectedStatus = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Color',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children:
                    [
                      Colors.blue,
                      Colors.green,
                      Colors.purple,
                      Colors.orange,
                      Colors.red,
                      Colors.teal,
                      Colors.pink,
                      Colors.amber,
                    ].map((color) {
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            selectedColor = color;
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selectedColor == color
                                  ? Colors.black
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _saveGoal,
            child: Text(isEdit ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }
}
