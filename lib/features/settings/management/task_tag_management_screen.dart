import 'package:flutter/material.dart';
import 'package:persona_codex/core/theme/gcash_theme.dart';

class TaskTagManagementScreen extends StatefulWidget {
  const TaskTagManagementScreen({super.key});

  @override
  State<TaskTagManagementScreen> createState() => _TaskTagManagementScreenState();
}

class _TaskTagManagementScreenState extends State<TaskTagManagementScreen> {
  // Temporary local state - will be replaced with database later
  final List<TaskTag> _tags = [
    TaskTag(id: '1', name: 'Work', color: Colors.blue, icon: Icons.work),
    TaskTag(id: '2', name: 'Personal', color: Colors.green, icon: Icons.person),
    TaskTag(id: '3', name: 'Urgent', color: Colors.red, icon: Icons.priority_high),
  ];

  void _showCreateEditDialog({TaskTag? tag}) {
    final isEdit = tag != null;
    final nameController = TextEditingController(text: tag?.name ?? '');
    Color selectedColor = tag?.color ?? Colors.blue;
    IconData selectedIcon = tag?.icon ?? Icons.label;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Tag' : 'Create Tag'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tag Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Color', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Colors.red,
                    Colors.orange,
                    Colors.yellow,
                    Colors.green,
                    Colors.blue,
                    Colors.indigo,
                    Colors.purple,
                    Colors.pink,
                    Colors.teal,
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
                    Icons.label,
                    Icons.work,
                    Icons.person,
                    Icons.home,
                    Icons.shopping_cart,
                    Icons.fitness_center,
                    Icons.school,
                    Icons.computer,
                    Icons.phone,
                    Icons.email,
                    Icons.priority_high,
                    Icons.star,
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
                    const SnackBar(content: Text('Please enter a tag name')),
                  );
                  return;
                }

                setState(() {
                  if (isEdit) {
                    final index = _tags.indexWhere((t) => t.id == tag.id);
                    _tags[index] = TaskTag(
                      id: tag.id,
                      name: nameController.text.trim(),
                      color: selectedColor,
                      icon: selectedIcon,
                    );
                  } else {
                    _tags.add(TaskTag(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text.trim(),
                      color: selectedColor,
                      icon: selectedIcon,
                    ));
                  }
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEdit ? 'Tag updated' : 'Tag created'),
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

  void _deleteTag(TaskTag tag) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tag'),
        content: Text('Are you sure you want to delete "${tag.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                _tags.removeWhere((t) => t.id == tag.id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tag deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GCashColors.background,
      appBar: AppBar(
        title: const Text('Manage Task Tags'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateEditDialog(),
            tooltip: 'Create Tag',
          ),
        ],
      ),
      body: _tags.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.label_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No tags yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create tags to organize your tasks',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _showCreateEditDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Tag'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: GCashSpacing.screenPadding,
              itemCount: _tags.length,
              itemBuilder: (context, index) {
                final tag = _tags[index];
                return Padding(
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
                          color: tag.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(tag.icon, color: tag.color),
                      ),
                      title: Text(
                        tag.name,
                        style: GCashTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showCreateEditDialog(tag: tag),
                            tooltip: 'Edit',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteTag(tag),
                            tooltip: 'Delete',
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: _tags.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showCreateEditDialog(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

// Simple TaskTag model - will be moved to domain layer later
class TaskTag {
  final String id;
  final String name;
  final Color color;
  final IconData icon;

  TaskTag({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
  });
}
