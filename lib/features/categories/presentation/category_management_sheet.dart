import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../domain/category.dart';
import 'categories_providers.dart';

class CategoryManagementSheet extends ConsumerWidget {
  const CategoryManagementSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Kategoriler',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  key: const Key('add-category-button'),
                  tooltip: 'Kategori ekle',
                  onPressed: () => _addCategory(context, ref),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            categoriesAsync.when(
              data: (categories) => ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.65,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return _CategoryListTile(
                      category: category,
                      onEdit: () => _renameCategory(context, ref, category),
                      onDelete: () => _deleteCategory(context, ref, category),
                    );
                  },
                ),
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => Text(
                'Kategoriler yüklenemedi: $error',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addCategory(BuildContext context, WidgetRef ref) async {
    final name = await _showCategoryNameDialog(context);
    if (name == null || !context.mounted) return;

    try {
      await ref.read(categoriesRepositoryProvider).addCustomCategory(name);
    } catch (error) {
      if (!context.mounted) return;
      _showError(context, 'Kategori eklenemedi: $error');
    }
  }

  Future<void> _renameCategory(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final name = await _showCategoryNameDialog(
      context,
      initialName: category.name,
    );
    if (name == null || !context.mounted) return;

    try {
      final wasRenamed = await ref
          .read(categoriesRepositoryProvider)
          .renameCustomCategory(category.id, name);
      if (!wasRenamed) {
        throw StateError('The category no longer exists.');
      }
    } catch (error) {
      if (!context.mounted) return;
      _showError(context, 'Kategori adı değiştirilemedi: $error');
    }
  }

  Future<void> _deleteCategory(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kategoriyi sil?'),
        content: Text(
          '"${category.name}" silinecek. İlişkili harcamalar korunur ancak '
          'kategorisiz kalır.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            key: const Key('confirm-delete-category-button'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final wasDeleted = await ref
          .read(categoriesRepositoryProvider)
          .deleteCustomCategory(category.id);
      if (!wasDeleted) {
        throw StateError('The category no longer exists.');
      }
    } catch (error) {
      if (!context.mounted) return;
      _showError(context, 'Kategori silinemedi: $error');
    }
  }

  Future<String?> _showCategoryNameDialog(
    BuildContext context, {
    String initialName = '',
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => _CategoryNameDialog(initialName: initialName),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CategoryListTile extends StatelessWidget {
  const _CategoryListTile({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey('category-${category.id}'),
      title: Text(category.name),
      subtitle: category.isDefault ? const Text('Varsayılan') : null,
      trailing: category.isDefault
          ? null
          : PopupMenuButton<String>(
              tooltip: 'Kategori işlemleri',
              onSelected: (action) {
                if (action == 'edit') {
                  onEdit();
                } else {
                  onDelete();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                PopupMenuItem(value: 'delete', child: Text('Sil')),
              ],
            ),
    );
  }
}

class _CategoryNameDialog extends StatefulWidget {
  const _CategoryNameDialog({required this.initialName});

  final String initialName;

  @override
  State<_CategoryNameDialog> createState() => _CategoryNameDialogState();
}

class _CategoryNameDialogState extends State<_CategoryNameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialName.isNotEmpty;

    return AlertDialog(
      title: Text(isEditing ? 'Kategori adını değiştir' : 'Yeni kategori'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          key: const Key('category-name-field'),
          controller: _nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Kategori adı',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Kategori adı boş olamaz.'
              : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          key: const Key('save-category-button'),
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, _nameController.text.trim());
          },
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}
