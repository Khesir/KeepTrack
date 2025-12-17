import 'package:flutter/material.dart';
import 'package:persona_codex/core/theme/gcash_theme.dart';

class TaskPriorityManagementScreen extends StatefulWidget {
  const TaskPriorityManagementScreen({super.key});

  @override
  State<TaskPriorityManagementScreen> createState() => _TaskPriorityManagementScreenState();
}

class _TaskPriorityManagementScreenState extends State<TaskPriorityManagementScreen> {
  // Configuration for task priorities (extends the enum with visual properties)
  final List<TaskPriorityConfig> _priorities = [
    TaskPriorityConfig(
      id: 'low',
      name: 'Low',
      color: Colors.green,
      icon: Icons.arrow_downward,
      order: 0,
      enabled: true,
    ),
    TaskPriorityConfig(
      id: 'medium',
      name: 'Medium',
      color: Colors.orange,
      icon: Icons.remove,
      order: 1,
      enabled: true,
    ),
    TaskPriorityConfig(
      id: 'high',
      name: 'High',
      color: Colors.red,
      icon: Icons.arrow_upward,
      order: 2,
      enabled: true,
    ),
    TaskPriorityConfig(
      id: 'urgent',
      name: 'Urgent',
      color: Colors.deepOrange,
      icon: Icons.priority_high,
      order: 3,
      enabled: true,
    ),
  ];

  void _showEditDialog(TaskPriorityConfig priority) {
    final nameController = TextEditingController(text: priority.name);
    Color selectedColor = priority.color;
    IconData selectedIcon = priority.icon;
    bool enabled = priority.enabled;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Priority Display'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    border: OutlineInputBorder(),
                    helperText: 'Customizes how this priority appears in the UI',
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Enabled'),
                  subtitle: const Text('Show this priority in task dropdowns'),
                  value: enabled,
                  onChanged: (value) {
                    setDialogState(() {
                      enabled = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text('Color', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Colors.green,
                    Colors.lightGreen,
                    Colors.orange,
                    Colors.deepOrange,
                    Colors.red,
                    Colors.pink,
                    Colors.purple,
                    Colors.blue,
                    Colors.grey,
                    Colors.brown,
                  ].map((color) {
                    final isSelected = selectedColor.value == color.value;
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
                          border: isSelected
                              ? Border.all(color: Colors.black, width: 3)
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Icon', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Icons.arrow_downward,
                    Icons.remove,
                    Icons.arrow_upward,
                    Icons.priority_high,
                    Icons.flag,
                    Icons.error,
                    Icons.warning,
                    Icons.info,
                    Icons.star,
                    Icons.bolt,
                  ].map((icon) {
                    final isSelected = selectedIcon.codePoint == icon.codePoint;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedIcon = icon;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected ? selectedColor : Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: isSelected ? Colors.white : Colors.grey[700],
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
                    const SnackBar(content: Text('Please enter a display name')),
                  );
                  return;
                }

                setState(() {
                  final index = _priorities.indexWhere((p) => p.id == priority.id);
                  _priorities[index] = TaskPriorityConfig(
                    id: priority.id,
                    name: nameController.text.trim(),
                    color: selectedColor,
                    icon: selectedIcon,
                    order: priority.order,
                    enabled: enabled,
                  );
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Priority configuration updated')),
                );
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedPriorities = List<TaskPriorityConfig>.from(_priorities)
      ..sort((a, b) => a.order.compareTo(b.order));

    return Scaffold(
      backgroundColor: GCashColors.background,
      appBar: AppBar(
        title: const Text('Manage Task Priorities'),
      ),
      body: ReorderableListView.builder(
        padding: GCashSpacing.screenPadding,
        itemCount: sortedPriorities.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            final item = sortedPriorities.removeAt(oldIndex);
            sortedPriorities.insert(newIndex, item);

            // Update order values
            for (int i = 0; i < sortedPriorities.length; i++) {
              final index = _priorities.indexWhere((p) => p.id == sortedPriorities[i].id);
              _priorities[index] = sortedPriorities[i].copyWith(order: i);
            }
          });
        },
        itemBuilder: (context, index) {
          final priority = sortedPriorities[index];
          return Padding(
            key: ValueKey(priority.id),
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: priority.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(priority.icon, color: priority.color),
                ),
                title: Text(
                  priority.name,
                  style: GCashTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: priority.enabled ? null : TextDecoration.lineThrough,
                  ),
                ),
                subtitle: Text(
                  priority.enabled ? 'Enabled' : 'Disabled',
                  style: TextStyle(
                    color: priority.enabled ? Colors.green : Colors.grey,
                    fontSize: 12,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.drag_handle, color: Colors.grey),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditDialog(priority),
                      tooltip: 'Edit',
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Configuration model for task priority display properties
class TaskPriorityConfig {
  final String id; // Matches enum value
  final String name;
  final Color color;
  final IconData icon;
  final int order;
  final bool enabled;

  TaskPriorityConfig({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.order,
    required this.enabled,
  });

  TaskPriorityConfig copyWith({
    String? id,
    String? name,
    Color? color,
    IconData? icon,
    int? order,
    bool? enabled,
  }) {
    return TaskPriorityConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      order: order ?? this.order,
      enabled: enabled ?? this.enabled,
    );
  }
}
