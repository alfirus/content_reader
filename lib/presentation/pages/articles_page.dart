import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/article/article_bloc.dart';
import '../blocs/settings/settings_bloc.dart';
import '../../data/models/article.dart';
import 'article_detail_page.dart';

class ArticlesPage extends StatefulWidget {
  const ArticlesPage({super.key});

  @override
  State<ArticlesPage> createState() => _ArticlesPageState();
}

class _ArticlesPageState extends State<ArticlesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    switch (_tabController.index) {
      case 0:
        context.read<ArticleBloc>().add(LoadArticles());
        break;
      case 1:
        context.read<ArticleBloc>().add(LoadUnreadArticles());
        break;
      case 2:
        context.read<ArticleBloc>().add(LoadSavedArticles());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return _buildDesktopLayout();
        }
        return _buildMobileLayout();
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Articles'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Unread'),
            Tab(text: 'Saved'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ArticleList(filter: ArticleFilter.all),
          _ArticleList(filter: ArticleFilter.unread),
          _ArticleList(filter: ArticleFilter.saved),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Articles'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Unread'),
              Tab(text: 'Saved'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ArticleList(filter: ArticleFilter.all),
            _ArticleList(filter: ArticleFilter.unread),
            _ArticleList(filter: ArticleFilter.saved),
          ],
        ),
      ),
    );
  }
}

class _ArticleList extends StatelessWidget {
  final ArticleFilter filter;

  const _ArticleList({required this.filter});

  @override
  Widget build(BuildContext context) {
    // Trigger load on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (filter) {
        case ArticleFilter.all:
          context.read<ArticleBloc>().add(LoadArticles());
          break;
        case ArticleFilter.unread:
          context.read<ArticleBloc>().add(LoadUnreadArticles());
          break;
        case ArticleFilter.saved:
          context.read<ArticleBloc>().add(LoadSavedArticles());
          break;
      }
    });

    return BlocBuilder<ArticleBloc, ArticleState>(
      builder: (context, state) {
        if (state is ArticleLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ArticleError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(state.message),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    switch (filter) {
                      case ArticleFilter.all:
                        context.read<ArticleBloc>().add(LoadArticles());
                        break;
                      case ArticleFilter.unread:
                        context.read<ArticleBloc>().add(LoadUnreadArticles());
                        break;
                      case ArticleFilter.saved:
                        context.read<ArticleBloc>().add(LoadSavedArticles());
                        break;
                    }
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is ArticleLoaded) {
          if (state.articles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.article_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    filter == ArticleFilter.all
                        ? 'No articles yet'
                        : filter == ArticleFilter.unread
                            ? 'All caught up!'
                            : 'No saved articles',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    filter == ArticleFilter.all
                        ? 'Add some RSS feeds to get started'
                        : filter == ArticleFilter.unread
                            ? 'Check back later for new articles'
                            : 'Save articles to read later',
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
              switch (filter) {
                case ArticleFilter.all:
                  context.read<ArticleBloc>().add(LoadArticles());
                  break;
                case ArticleFilter.unread:
                  context.read<ArticleBloc>().add(LoadUnreadArticles());
                  break;
                case ArticleFilter.saved:
                  context.read<ArticleBloc>().add(LoadSavedArticles());
                  break;
              }
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                  return _buildDesktopList(context, state.articles);
                }
                return _buildMobileList(context, state.articles);
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildDesktopList(BuildContext context, List<Article> articles) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: articles.length,
      itemBuilder: (context, index) {
        return _ArticleCardDesktop(article: articles[index]);
      },
    );
  }

  Widget _buildMobileList(BuildContext context, List<Article> articles) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: articles.length,
      itemBuilder: (context, index) {
        return _ArticleCard(article: articles[index]);
      },
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final Article article;

  const _ArticleCard({required this.article});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.read<ArticleBloc>().add(MarkArticleAsRead(article));
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MultiBlocProvider(
                providers: [
                  BlocProvider.value(value: context.read<ArticleBloc>()),
                  BlocProvider.value(value: context.read<SettingsBloc>()),
                ],
                child: ArticleDetailPage(article: article),
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image - full width
            if (article.imageUrl != null && article.imageUrl!.isNotEmpty)
              SizedBox(
                height: 180,
                width: double.infinity,
                child: Image.network(
                  article.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (!article.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          article.title,
                          style: TextStyle(
                            fontWeight: article.isRead ? FontWeight.normal : FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (article.summary.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      article.summary.replaceAll(RegExp(r'<[^>]*>'), ''),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (article.author.isNotEmpty) ...[
                        Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            article.author,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        dateFormat.format(article.published),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          article.isSaved ? Icons.bookmark : Icons.bookmark_outline,
                          color: article.isSaved ? Theme.of(context).colorScheme.primary : null,
                        ),
                        onPressed: () {
                          context.read<ArticleBloc>().add(ToggleArticleSaved(article));
                        },
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleCardDesktop extends StatelessWidget {
  final Article article;

  const _ArticleCardDesktop({required this.article});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.read<ArticleBloc>().add(MarkArticleAsRead(article));
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MultiBlocProvider(
                providers: [
                  BlocProvider.value(value: context.read<ArticleBloc>()),
                  BlocProvider.value(value: context.read<SettingsBloc>()),
                ],
                child: ArticleDetailPage(article: article),
              ),
            ),
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image on the left
            if (article.imageUrl != null && article.imageUrl!.isNotEmpty)
              SizedBox(
                width: 200,
                height: 140,
                child: Image.network(
                  article.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Unread indicator
                        if (!article.isRead)
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            article.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: article.isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (article.summary.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        article.summary.replaceAll(RegExp(r'<[^>]*>'), ''),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (article.author.isNotEmpty) ...[
                          Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            article.author,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 16),
                        ],
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(article.published),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            article.isSaved ? Icons.bookmark : Icons.bookmark_outline,
                            color: article.isSaved ? Theme.of(context).colorScheme.primary : null,
                          ),
                          onPressed: () {
                            context.read<ArticleBloc>().add(ToggleArticleSaved(article));
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
