import 'package:flutter/material.dart';
import '../../services/admin_category_service.dart';
import '../../models/admin_category.dart';

class ManageCategoryDialog extends StatefulWidget {
  final VoidCallback? onCategoriesChanged;

  const ManageCategoryDialog({
    super.key,
    this.onCategoriesChanged,
  });

  @override
  State<ManageCategoryDialog> createState() => _ManageCategoryDialogState();
}

class _ManageCategoryDialogState extends State<ManageCategoryDialog> {
  final AdminCategoryService _categoryService = AdminCategoryService();
  List<AdminCategory> _categories = [];
  bool _isLoading = true;
  final Map<String, TextEditingController> _editingControllers = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    for (final controller in _editingControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await _categoryService.getCategories(forceRefresh: true);
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading categories: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addCategory(String name) async {
    if (name.trim().isEmpty) return;

    final category = await _categoryService.addCategory(name);
    if (category != null) {
      await _loadCategories();
      if (widget.onCategoriesChanged != null) {
        widget.onCategoriesChanged!();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add category'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateCategory(String id, String name) async {
    if (name.trim().isEmpty) return;

    final success = await _categoryService.updateCategory(id, name);
    if (success) {
      await _loadCategories();
      if (widget.onCategoriesChanged != null) {
        widget.onCategoriesChanged!();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update category'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteCategory(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text('Are you sure you want to delete this category?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _categoryService.deleteCategory(id);
      if (success) {
        await _loadCategories();
        if (widget.onCategoriesChanged != null) {
          widget.onCategoriesChanged!();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete category'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Manage Categories',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isEditing = _editingControllers.containsKey(category.id);

                    return ListTile(
                      title: isEditing
                          ? TextField(
                              controller: _editingControllers[category.id],
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                              ),
                              autofocus: true,
                              onSubmitted: (value) {
                                _updateCategory(category.id, value);
                                _editingControllers.remove(category.id)?.dispose();
                              },
                            )
                          : Text(category.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              setState(() {
                                _editingControllers[category.id] =
                                    TextEditingController(text: category.name);
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteCategory(category.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            _AddCategoryField(onAdd: _addCategory),
          ],
        ),
      ),
    );
  }
}

class _AddCategoryField extends StatefulWidget {
  final Function(String) onAdd;

  const _AddCategoryField({required this.onAdd});

  @override
  State<_AddCategoryField> createState() => _AddCategoryFieldState();
}

class _AddCategoryFieldState extends State<_AddCategoryField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleAdd() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) {
      widget.onAdd(name);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Enter category name',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _handleAdd(),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _handleAdd,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
