import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../blocs/article/article_bloc.dart';
import '../../data/models/article.dart';

class ArticleDetailPage extends StatelessWidget {
  final Article article;

  const ArticleDetailPage({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMMM d, yyyy');
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: article.imageUrl != null ? 250 : 0,
            pinned: true,
            flexibleSpace: article.imageUrl != null
                ? FlexibleSpaceBar(
                    background: Image.network(
                      article.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, size: 64),
                      ),
                    ),
                  )
                : null,
            actions: [
              IconButton(
                icon: Icon(
                  article.isSaved ? Icons.bookmark : Icons.bookmark_outline,
                ),
                onPressed: () {
                  context.read<ArticleBloc>().add(ToggleArticleSaved(article));
                  Navigator.pop(context);
                },
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  Share.share('${article.title}\n${article.link}');
                },
              ),
              IconButton(
                icon: const Icon(Icons.open_in_browser),
                onPressed: () async {
                  final uri = Uri.parse(article.link);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ],
          ),
          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  article.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (article.author.isNotEmpty) ...[
                      const Icon(Icons.person_outline, size: 16),
                      const SizedBox(width: 4),
                      Text(article.author),
                      const SizedBox(width: 16),
                    ],
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 4),
                    Text(dateFormat.format(article.published)),
                  ],
                ),
                const Divider(height: 32),
                SelectableText(
                  article.content.isNotEmpty 
                      ? _stripHtml(article.content) 
                      : article.summary.isNotEmpty 
                          ? _stripHtml(article.summary) 
                          : 'No content available',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),
                if (article.link.isNotEmpty)
                  Center(
                    child: FilledButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(article.link);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Read Full Article'),
                    ),
                  ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _stripHtml(String htmlString) {
    return htmlString
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&lt;'), '<')
        .replaceAll(RegExp(r'&gt;'), '>')
        .replaceAll(RegExp(r'&quot;'), '"')
        .trim();
  }
}
