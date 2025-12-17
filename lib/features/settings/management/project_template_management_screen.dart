import 'package:flutter/material.dart';
import 'package:persona_codex/core/theme/gcash_theme.dart';

class ProjectTemplateManagementScreen extends StatefulWidget {
  const ProjectTemplateManagementScreen({super.key});

  @override
  State<ProjectTemplateManagementScreen> createState() => _ProjectTemplateManagementScreenState();
}

class _ProjectTemplateManagementScreenState extends State<ProjectTemplateManagementScreen> {
  // Temporary local state - will be replaced with database later
  final List<ProjectTemplate> _templates = [
    ProjectTemplate(
      id: '1',
      name: 'Software Development',
      description: 'Standard software development project with phases',
      color: Colors.blue,
      icon: Icons.code,
      defaultTasks: ['Planning', 'Development', 'Testing', 'Deployment'],
    ),
    ProjectTemplate(
      id: '2',
      name: 'Marketing Campaign',
      description: 'Marketing project template',
      color: Colors.orange,
      icon: Icons.campaign,
      defaultTasks: ['Research', 'Strategy', 'Content Creation', 'Launch'],
    ),
  ];

  void _showCreateEditDialog({ProjectTemplate? template}) {
    final isEdit = template != null;
    final nameController = TextEditingController(text: template?.name ?? '');
    final descController = TextEditingController(text: template?.description ?? '');
    Color selectedColor = template?.color ?? Colors.blue;
    IconData selectedIcon = template?.icon ?? Icons.folder;
    List<String> defaultTasks = List<String>.from(template?.defaultTasks ?? []);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Project Template' : 'Create Project Template'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Template Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      helperText: 'Brief description of this template',
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
                      Icons.folder,
                      Icons.code,
                      Icons.campaign,
                      Icons.design_services,
                      Icons.shopping_cart,
                      Icons.business,
                      Icons.school,
                      Icons.science,
                      Icons.build,
                      Icons.restaurant,
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
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Default Tasks',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      FilledButton.icon(
                        onPressed: () {
                          final taskController = TextEditingController();
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Add Task'),
                              content: TextField(
                                controller: taskController,
                                decoration: const InputDecoration(
                                  labelText: 'Task Name',
                                  border: OutlineInputBorder(),
                                ),
                                autofocus: true,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () {
                                    if (taskController.text.trim().isNotEmpty) {
                                      setDialogState(() {
                                        defaultTasks.add(taskController.text.trim());
                                      });
                                      Navigator.pop(ctx);
                                    }
                                  },
                                  child: const Text('Add'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Task'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (defaultTasks.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'No default tasks',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    )
                  else
                    Container(
                      constraints: const BoxConstraints(maxHeight: 150),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: defaultTasks.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[300]),
                        itemBuilder: (context, index) {
                          return ListTile(
                            dense: true,
                            leading: Text('${index + 1}.'),
                            title: Text(defaultTasks[index]),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                              onPressed: () {
                                setDialogState(() {
                                  defaultTasks.removeAt(index);
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
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
                    const SnackBar(content: Text('Please enter a template name')),
                  );
                  return;
                }

                setState(() {
                  if (isEdit) {
                    final index = _templates.indexWhere((t) => t.id == template.id);
                    _templates[index] = ProjectTemplate(
                      id: template.id,
                      name: nameController.text.trim(),
                      description: descController.text.trim(),
                      color: selectedColor,
                      icon: selectedIcon,
                      defaultTasks: defaultTasks,
                    );
                  } else {
                    _templates.add(ProjectTemplate(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text.trim(),
                      description: descController.text.trim(),
                      color: selectedColor,
                      icon: selectedIcon,
                      defaultTasks: defaultTasks,
                    ));
                  }
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEdit ? 'Template updated' : 'Template created'),
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

  void _deleteTemplate(ProjectTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text('Are you sure you want to delete "${template.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                _templates.removeWhere((t) => t.id == template.id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Template deleted')),
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
        title: const Text('Manage Project Templates'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateEditDialog(),
            tooltip: 'Create Template',
          ),
        ],
      ),
      body: _templates.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No templates yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create templates for recurring project types',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _showCreateEditDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Template'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: GCashSpacing.screenPadding,
              itemCount: _templates.length,
              itemBuilder: (context, index) {
                final template = _templates[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: template.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(template.icon, color: template.color),
                      ),
                      title: Text(
                        template.name,
                        style: GCashTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        template.description,
                        style: GCashTextStyles.bodySmall.copyWith(
                          color: GCashColors.textSecondary,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showCreateEditDialog(template: template),
                            tooltip: 'Edit',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteTemplate(template),
                            tooltip: 'Delete',
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Default Tasks:',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              if (template.defaultTasks.isEmpty)
                                Text(
                                  'No default tasks',
                                  style: TextStyle(color: Colors.grey[600]),
                                )
                              else
                                ...template.defaultTasks.asMap().entries.map((entry) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: template.color.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${entry.key + 1}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: template.color,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(entry.value),
                                      ],
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: _templates.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showCreateEditDialog(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

// ProjectTemplate model - will be moved to domain layer later
class ProjectTemplate {
  final String id;
  final String name;
  final String description;
  final Color color;
  final IconData icon;
  final List<String> defaultTasks;

  ProjectTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.icon,
    required this.defaultTasks,
  });
}
