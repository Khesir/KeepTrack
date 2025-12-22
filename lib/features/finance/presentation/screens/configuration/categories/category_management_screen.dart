import 'package:flutter/material.dart';
import 'package:persona_codex/core/di/service_locator.dart';
import 'package:persona_codex/core/state/stream_builder_widget.dart';
import 'package:persona_codex/core/theme/gcash_theme.dart';
import 'package:persona_codex/features/finance/modules/finance_category/domain/entities/finance_category.dart';
import 'package:persona_codex/features/finance/presentation/screens/configuration/categories/widgets/category_management_dialog.dart';
import 'package:persona_codex/shared/infrastructure/supabase/supabase_service.dart';

import '../../../../modules/finance_category/domain/entities/finance_category_enums.dart';
import '../../../state/finance_category_controller.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  late final FinanceCategoryController _controller;
  late final SupabaseService supabaseService;
  @override
  void initState() {
    super.initState();
    _controller = locator.get<FinanceCategoryController>();
    supabaseService = locator.get<SupabaseService>();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showCreateEditDialog({FinanceCategory? category}) {
    showDialog(
      context: context,
      builder: (context) => CategoryManagementDialog(
        userId: supabaseService.userId!,
        financeCategory: category,
        onSave: (savedCategory) {
          if (category != null) {
            _controller.updateCategory(savedCategory);
          } else {
            _controller.createCategory(savedCategory);
          }
        },
      ),
    );
  }

  void _deleteCategory(FinanceCategory category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _controller.deleteCategory(category.id!);
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Category deleted')));
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
        title: const Text('Manage Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateEditDialog(),
            tooltip: 'Create Category',
          ),
        ],
      ),
      body: AsyncStreamBuilder<List<FinanceCategory>>(
        state: _controller,
        builder: (context, categories) {
          // Group categories by type
          final groupedCategories = <CategoryType, List<FinanceCategory>>{};
          for (final category in categories) {
            groupedCategories
                .putIfAbsent(category.type, () => [])
                .add(category);
          }

          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No categories yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create categories to organize income and expenses',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _showCreateEditDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Category'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: GCashSpacing.screenPadding,
            children: CategoryType.values.map((type) {
              final categoriesOfType = groupedCategories[type] ?? [];
              if (categoriesOfType.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: type.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(type.icon, color: type.color, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          type.displayName,
                          style: GCashTextStyles.h3.copyWith(color: type.color),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: type.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${categoriesOfType.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: type.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...categoriesOfType.map((category) {
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
                              color: category.type.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              category.type.icon,
                              color: category.type.color,
                            ),
                          ),
                          title: Text(
                            category.name,
                            style: GCashTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () =>
                                    _showCreateEditDialog(category: category),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteCategory(category),
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              );
            }).toList(),
          );
        },
        loadingBuilder: (context) =>
            const Center(child: CircularProgressIndicator()),
        errorBuilder: (context, message) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(message),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _controller.loadCategories(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
