import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/feed/feed_bloc.dart';
import 'feeds_page.dart';
import 'articles_page.dart';
import 'saved_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _isExtended = true;
  int _previousFeedCount = 0;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.rss_feed_outlined,
      selectedIcon: Icons.rss_feed,
      label: 'Feeds',
    ),
    NavigationItem(
      icon: Icons.article_outlined,
      selectedIcon: Icons.article,
      label: 'Articles',
    ),
    NavigationItem(
      icon: Icons.bookmark_outline,
      selectedIcon: Icons.bookmark,
      label: 'Saved',
    ),
    NavigationItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  final List<Widget> _pages = [
    const FeedsPage(),
    const ArticlesPage(),
    const SavedPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocListener<FeedBloc, FeedState>(
      listener: (context, state) {
        if (state is FeedError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is FeedLoaded) {
          // Show success message when new feed is added
          if (state.feeds.length > _previousFeedCount && _previousFeedCount > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Feed added! Tap Articles to see articles.'),
                backgroundColor: Colors.green,
                action: SnackBarAction(
                  label: 'View',
                  textColor: Colors.white,
                  onPressed: () {
                    setState(() => _selectedIndex = 1);
                  },
                ),
              ),
            );
          }
          _previousFeedCount = state.feeds.length;
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Desktop layout (width > 800)
          if (constraints.maxWidth > 800) {
            return _buildDesktopLayout();
          }
          // Mobile layout
          return _buildMobileLayout();
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isExtended ? 240 : 80,
            child: _buildSidebar(isDesktop: true),
          ),
          const VerticalDivider(width: 1),
          // Content
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: _navigationItems.map((item) {
          return NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSidebar({required bool isDesktop}) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Header
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.rss_feed,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                if (_isExtended) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Content Reader',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                if (isDesktop)
                  IconButton(
                    icon: Icon(_isExtended ? Icons.chevron_left : Icons.chevron_right),
                    onPressed: () {
                      setState(() => _isExtended = !_isExtended);
                    },
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Navigation items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _navigationItems.length,
              itemBuilder: (context, index) {
                final item = _navigationItems[index];
                final isSelected = _selectedIndex == index;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Material(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() => _selectedIndex = index);
                      },
                      child: Container(
                        height: 48,
                        padding: EdgeInsets.symmetric(
                          horizontal: _isExtended ? 16 : 0,
                        ),
                        child: Row(
                          mainAxisAlignment: _isExtended
                              ? MainAxisAlignment.start
                              : MainAxisAlignment.center,
                          children: [
                            Icon(
                              isSelected ? item.selectedIcon : item.icon,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            if (_isExtended) ...[
                              const SizedBox(width: 12),
                              Text(
                                item.label,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
