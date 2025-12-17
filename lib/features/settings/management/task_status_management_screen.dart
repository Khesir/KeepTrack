import 'package:flutter/material.dart';
import 'package:persona_codex/core/theme/gcash_theme.dart';

class TaskStatusManagementScreen extends StatefulWidget {
  const TaskStatusManagementScreen({super.key});

  @override
  State<TaskStatusManagementScreen> createState() => _TaskStatusManagementScreenState();
}

class _TaskStatusManagementScreenState extends State<TaskStatusManagementScreen> {
  // Configuration for task statuses (extends the enum with visual properties)
  final List<TaskStatusConfig> _statuses = [
    TaskStatusConfig(
      id: 'todo',
      name: 'To Do',
      color: Colors.grey,
      icon: Icons.radio_button_unchecked,
      order: 0,
      enabled: true,
    ),
    TaskStatusConfig(
      id: 'in_progress',
      name: 'In Progress',
      color: Colors.blue,
      icon: Icons.pending,
      order: 1,
      enabled: true,
    ),
    TaskStatusConfig(
      id: 'completed',
      name: 'Completed',
      color: Colors.green,
      icon: Icons.check_circle,
      order: 2,
      enabled: true,
    ),
    TaskStatusConfig(
      id: 'cancelled',
      name: 'Cancelled',
      color: Colors.red,
      icon: Icons.cancel,
      order: 3,
      enabled: true,
    ),
  ];

  void _showEditDialog(TaskStatusConfig status) {
    final nameController = TextEditingController(text: status.name);
    Color selectedColor = status.color;
    IconData selectedIcon = status.icon;
    bool enabled = status.enabled;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Status Display'),
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
                    helperText: 'Customizes how this status appears in the UI',
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Enabled'),
                  subtitle: const Text('Show this status in task dropdowns'),
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
                    Colors.grey,
                    Colors.red,
                    Colors.orange,
                    Colors.yellow,
                    Colors.green,
                    Colors.blue,
                    Colors.indigo,
                    Colors.purple,
                    Colors.pink,
                    Colors.teal,
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
                    Icons.radio_button_unchecked,
                    Icons.pending,
                    Icons.check_circle,
                    Icons.cancel,
                    Icons.circle,
                    Icons.access_time,
                    Icons.done,
                    Icons.close,
                    Icons.pause_circle,
                    Icons.play_circle,
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
                  final index = _statuses.indexWhere((s) => s.id == status.id);
                  _statuses[index] = TaskStatusConfig(
                    id: status.id,
                    name: nameController.text.trim(),
                    color: selectedColor,
                    icon: selectedIcon,
                    order: status.order,
                    enabled: enabled,
                  );
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Status configuration updated')),
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
    final sortedStatuses = List<TaskStatusConfig>.from(_statuses)
      ..sort((a, b) => a.order.compareTo(b.order));

    return Scaffold(
      backgroundColor: GCashColors.background,
      appBar: AppBar(
        title: const Text('Manage Task Statuses'),
      ),
      body: ReorderableListView.builder(
        padding: GCashSpacing.screenPadding,
        itemCount: sortedStatuses.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            final item = sortedStatuses.removeAt(oldIndex);
            sortedStatuses.insert(newIndex, item);

            // Update order values
            for (int i = 0; i < sortedStatuses.length; i++) {
              final index = _statuses.indexWhere((s) => s.id == sortedStatuses[i].id);
              _statuses[index] = sortedStatuses[i].copyWith(order: i);
            }
          });
        },
        itemBuilder: (context, index) {
          final status = sortedStatuses[index];
          return Padding(
            key: ValueKey(status.id),
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
                    color: status.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(status.icon, color: status.color),
                ),
                title: Text(
                  status.name,
                  style: GCashTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: status.enabled ? null : TextDecoration.lineThrough,
                  ),
                ),
                subtitle: Text(
                  status.enabled ? 'Enabled' : 'Disabled',
                  style: TextStyle(
                    color: status.enabled ? Colors.green : Colors.grey,
                    fontSize: 12,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.drag_handle, color: Colors.grey),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditDialog(status),
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

// Configuration model for task status display properties
class TaskStatusConfig {
  final String id; // Matches enum value
  final String name;
  final Color color;
  final IconData icon;
  final int order;
  final bool enabled;

  TaskStatusConfig({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.order,
    required this.enabled,
  });

  TaskStatusConfig copyWith({
    String? id,
    String? name,
    Color? color,
    IconData? icon,
    int? order,
    bool? enabled,
  }) {
    return TaskStatusConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      order: order ?? this.order,
      enabled: enabled ?? this.enabled,
    );
  }
}
