import 'package:flutter/material.dart';
import 'package:persona_codex/core/di/service_locator.dart';
import 'package:persona_codex/core/state/stream_state.dart';
import 'package:persona_codex/core/state/stream_builder_widget.dart';
import 'package:persona_codex/features/finance/modules/goal/domain/entities/goal.dart';
import 'package:persona_codex/features/finance/presentation/state/goal_controller.dart';

class GoalsManagementScreen extends StatefulWidget {
  const GoalsManagementScreen({super.key});

  @override
  State<GoalsManagementScreen> createState() => _GoalsManagementScreenState();
}

class _GoalsManagementScreenState extends State<GoalsManagementScreen> {
  late final GoalController _controller;

  @override
  void initState() {
    super.initState();
    _controller = locator.get<GoalController>();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showCreateEditDialog({Goal? goal}) {
    final isEdit = goal != null;
    final nameController = TextEditingController(text: goal?.name ?? '');
    final descriptionController = TextEditingController(
      text: goal?.description ?? '',
    );
    final targetAmountController = TextEditingController(
      text: goal?.targetAmount.toString() ?? '',
    );
    final currentAmountController = TextEditingController(
      text: goal?.currentAmount.toString() ?? '0',
    );
    final monthlyContributionController = TextEditingController(
      text: goal?.monthlyContribution.toString() ?? '0',
    );
    DateTime? selectedTargetDate = goal?.targetDate;
    GoalStatus selectedStatus = goal?.status ?? GoalStatus.active;
    Color selectedColor = goal?.colorHex != null
        ? Color(int.parse(goal!.colorHex!.replaceFirst('#', '0xFF')))
        : Colors.blue;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
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
                        lastDate: DateTime.now().add(
                          const Duration(days: 3650),
                        ),
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
                  children: [
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
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a goal name')),
                  );
                  return;
                }
                if (targetAmountController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a target amount'),
                    ),
                  );
                  return;
                }

                final targetAmount =
                    double.tryParse(targetAmountController.text) ?? 0;
                final currentAmount =
                    double.tryParse(currentAmountController.text) ?? 0;
                final monthlyContribution =
                    double.tryParse(monthlyContributionController.text) ?? 0;

                final colorHex =
                    '#${selectedColor.value.toRadixString(16).substring(2)}';

                final goalEntity = Goal(
                  id: goal?.id,
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                  targetAmount: targetAmount,
                  currentAmount: currentAmount,
                  targetDate: selectedTargetDate,
                  colorHex: colorHex,
                  status: selectedStatus,
                  monthlyContribution: monthlyContribution,
                );

                if (isEdit) {
                  _controller.updateGoal(goalEntity);
                } else {
                  _controller.createGoal(goalEntity);
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEdit ? 'Goal updated' : 'Goal created'),
                  ),
                );
              },
              child: Text(isEdit ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteGoal(Goal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Are you sure you want to delete "${goal.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _controller.deleteGoal(goal.id!);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Goal deleted')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Goals')),
      body: AsyncStreamBuilder<List<Goal>>(
        state: _controller,
        builder: (context, goals) {
          if (goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 64,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No goals yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first savings goal',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              final color = goal.colorHex != null
                  ? Color(int.parse(goal.colorHex!.replaceFirst('#', '0xFF')))
                  : Colors.blue;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color,
                    child: const Icon(Icons.flag, color: Colors.white),
                  ),
                  title: Text(goal.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal.description),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: goal.progress / 100,
                        backgroundColor: color.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${goal.currentAmount.toStringAsFixed(2)} / \$${goal.targetAmount.toStringAsFixed(2)} (${goal.progress.toStringAsFixed(1)}%)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showCreateEditDialog(goal: goal);
                      } else if (value == 'delete') {
                        _deleteGoal(goal);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
        loadingBuilder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorBuilder: (context, message) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(message),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _controller.loadGoals(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Goal'),
      ),
    );
  }
}
