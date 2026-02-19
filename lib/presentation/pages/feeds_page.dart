import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/feed/feed_bloc.dart';
import '../blocs/category/category_bloc.dart';
import '../../data/models/feed.dart';
import '../../data/models/category.dart';

class FeedsPage extends StatefulWidget {
  const FeedsPage({super.key});

  @override
  State<FeedsPage> createState() => _FeedsPageState();
}

class _FeedsPageState extends State<FeedsPage> {
  int? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Desktop layout
        if (constraints.maxWidth > 800) {
          return _buildDesktopLayout();
        }
        // Mobile layout
        return _buildMobileLayout();
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Categories sidebar
        SizedBox(
          width: 240,
          child: _buildCategorySidebar(),
        ),
        const VerticalDivider(width: 1),
        // Feeds list
        Expanded(child: _buildFeedsContent()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feeds'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<FeedBloc>().add(RefreshFeeds());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryChips(),
          const Divider(height: 1),
          Expanded(child: _buildFeedsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFeedDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategorySidebar() {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Categories',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () => _showAddCategoryDialog(context),
                  tooltip: 'Add Category',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: BlocBuilder<CategoryBloc, CategoryState>(
              builder: (context, state) {
                if (state is CategoryLoaded) {
                  return ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      _buildCategoryTile(
                        context,
                        null,
                        'All Feeds',
                        Icons.all_inbox,
                        null,
                      ),
                      ...state.categories.map((category) {
                        return _buildCategoryTile(
                          context,
                          category.id,
                          category.name,
                          Icons.folder,
                          Color(category.color),
                        );
                      }),
                    ],
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(
    BuildContext context,
    int? categoryId,
    String name,
    IconData icon,
    Color? color,
  ) {
    final isSelected = _selectedCategoryId == categoryId;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            setState(() => _selectedCategoryId = categoryId);
            if (categoryId == null) {
              context.read<FeedBloc>().add(LoadFeeds());
            } else {
              context.read<FeedBloc>().add(LoadFeedsByCategory(categoryId));
            }
          },
          onLongPress: categoryId != null
              ? () => _showCategoryOptions(context, categoryId!, name, color ?? Colors.blue)
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                if (color != null)
                  CircleAvatar(
                    backgroundColor: color,
                    radius: 4,
                  )
                else
                  Icon(
                    icon,
                    size: 20,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, categoryState) {
        if (categoryState is CategoryLoaded) {
          return SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: const Text('All'),
                    selected: _selectedCategoryId == null,
                    onSelected: (_) {
                      setState(() => _selectedCategoryId = null);
                      context.read<FeedBloc>().add(LoadFeeds());
                    },
                  ),
                ),
                ...categoryState.categories.map((category) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(category.name),
                      selected: _selectedCategoryId == category.id,
                      avatar: CircleAvatar(
                        backgroundColor: Color(category.color),
                        radius: 8,
                      ),
                      onSelected: (_) {
                        setState(() => _selectedCategoryId = category.id);
                        context.read<FeedBloc>().add(LoadFeedsByCategory(category.id!));
                      },
                    ),
                  );
                }),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddCategoryDialog(context),
                  tooltip: 'Add Category',
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildFeedsContent() {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedCategoryId == null ? 'All Feeds' : 'Feeds'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<FeedBloc>().add(RefreshFeeds());
            },
          ),
        ],
      ),
      body: _buildFeedsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFeedDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFeedsList() {
    return BlocBuilder<FeedBloc, FeedState>(
      builder: (context, state) {
        if (state is FeedLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is FeedError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(state.message),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.read<FeedBloc>().add(LoadFeeds()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is FeedLoaded) {
          if (state.feeds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rss_feed, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No feeds yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first RSS feed',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<FeedBloc>().add(RefreshFeeds());
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.feeds.length,
              itemBuilder: (context, index) {
                final feed = state.feeds[index];
                final unreadCount = state.unreadCounts[feed.id] ?? 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showFeedOptions(context, feed),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: feed.favicon.isNotEmpty
                                ? Image.network(
                                    feed.favicon,
                                    width: 48,
                                    height: 48,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 48,
                                      height: 48,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.rss_feed),
                                    ),
                                  )
                                : Container(
                                    width: 48,
                                    height: 48,
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    child: Icon(
                                      Icons.rss_feed,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  feed.title,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  feed.description,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
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

        return const SizedBox.shrink();
      },
    );
  }

  void _showAddFeedDialog(BuildContext context) {
    final urlController = TextEditingController();
    int? selectedCategoryId = _selectedCategoryId;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add RSS Feed'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    hintText: 'Enter RSS feed URL',
                    labelText: 'URL',
                    prefixIcon: Icon(Icons.link),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),
                BlocBuilder<CategoryBloc, CategoryState>(
                  builder: (context, categoryState) {
                    if (categoryState is CategoryLoaded && categoryState.categories.isNotEmpty) {
                      return DropdownButtonFormField<int?>(
                        value: selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Category (optional)',
                          prefixIcon: Icon(Icons.folder),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('No Category'),
                          ),
                          ...categoryState.categories.map((cat) {
                            return DropdownMenuItem<int?>(
                              value: cat.id,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Color(cat.color),
                                    radius: 8,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(cat.name),
                                ],
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setDialogState(() => selectedCategoryId = value);
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (urlController.text.isNotEmpty) {
                  context.read<FeedBloc>().add(
                    AddFeed(urlController.text.trim(), categoryId: selectedCategoryId),
                  );
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFeedOptions(BuildContext context, Feed feed) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Feed'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showEditFeedDialog(context, feed);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Feed', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmDeleteFeed(context, feed);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditFeedDialog(BuildContext context, Feed feed) {
    final titleController = TextEditingController(text: feed.title);
    final urlController = TextEditingController(text: feed.url);
    int? selectedCategoryId = feed.categoryId;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Feed'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(labelText: 'URL'),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),
                BlocBuilder<CategoryBloc, CategoryState>(
                  builder: (context, categoryState) {
                    if (categoryState is CategoryLoaded) {
                      return DropdownButtonFormField<int?>(
                        value: selectedCategoryId,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('No Category'),
                          ),
                          ...categoryState.categories.map((cat) {
                            return DropdownMenuItem<int?>(
                              value: cat.id,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Color(cat.color),
                                    radius: 8,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(cat.name),
                                ],
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setDialogState(() => selectedCategoryId = value);
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (titleController.text.isNotEmpty && urlController.text.isNotEmpty) {
                  final updatedFeed = feed.copyWith(
                    title: titleController.text.trim(),
                    url: urlController.text.trim(),
                    categoryId: selectedCategoryId,
                  );
                  context.read<FeedBloc>().add(UpdateFeed(updatedFeed));
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteFeed(BuildContext context, Feed feed) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Feed'),
        content: Text('Are you sure you want to delete "${feed.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (feed.id != null) {
                context.read<FeedBloc>().add(DeleteFeed(feed.id!));
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    int selectedColor = 0xFF6366F1;

    final colors = [
      0xFF6366F1, // Indigo
      0xFFEF4444, // Red
      0xFF22C55E, // Green
      0xFFF59E0B, // Amber
      0xFF8B5CF6, // Violet
      0xFF06B6D4, // Cyan
      0xFFEC4899, // Pink
      0xFF78716C, // Stone
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Category'),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: 'Category name',
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.folder),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Color:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colors.map((color) {
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() => selectedColor = color);
                      },
                      child: CircleAvatar(
                        backgroundColor: Color(color),
                        radius: 20,
                        child: selectedColor == color
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  context.read<CategoryBloc>().add(
                    AddCategory(nameController.text.trim(), selectedColor),
                  );
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryOptions(BuildContext context, int categoryId, String name, Color color) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Category'),
              onTap: () {
                Navigator.pop(sheetContext);
                // TODO: Implement edit category
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Category', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmDeleteCategory(context, categoryId, name);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCategory(BuildContext context, int categoryId, String name) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "$name"? Feeds in this category will be uncategorized.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<CategoryBloc>().add(DeleteCategory(categoryId));
              Navigator.pop(dialogContext);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
