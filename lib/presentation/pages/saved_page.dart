import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/article/article_bloc.dart';
import '../../data/models/article.dart';
import 'article_detail_page.dart';
import 'package:intl/intl.dart';

class SavedPage extends StatefulWidget {
  const SavedPage({super.key});

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  @override
  void initState() {
    super.initState();
    context.read<ArticleBloc>().add(LoadSavedArticles());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Articles'),
      ),
      body: BlocBuilder<ArticleBloc, ArticleState>(
        builder: (context, state) {
          if (state is ArticleLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ArticleError) {
            return Center(child: Text(state.message));
          }

          if (state is ArticleLoaded) {
            if (state.articles.isEmpty) {
              return const Center(
                child: Text('No saved articles yet'),
              );
            }

            return ListView.builder(
              itemCount: state.articles.length,
              itemBuilder: (context, index) {
                final article = state.articles[index];
                return _SavedArticleCard(article: article);
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _SavedArticleCard extends StatelessWidget {
  final Article article;

  const _SavedArticleCard({required this.article});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(
          article.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          dateFormat.format(article.published),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.bookmark),
          onPressed: () {
            context.read<ArticleBloc>().add(ToggleArticleSaved(article));
          },
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<ArticleBloc>(),
                child: ArticleDetailPage(article: article),
              ),
            ),
          );
        },
      ),
    );
  }
}
