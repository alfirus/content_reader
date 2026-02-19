import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../blocs/article/article_bloc.dart';
import '../blocs/settings/settings_bloc.dart';
import '../../data/models/article.dart';
import '../../core/ai/ai_service.dart';

class ArticleDetailPage extends StatefulWidget {
  final Article article;

  const ArticleDetailPage({super.key, required this.article});

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  bool _isSummarizing = false;
  String? _aiSummary;

  @override
  void initState() {
    super.initState();
    _aiSummary = widget.article.summary;
  }

  Future<void> _summarizeArticle() async {
    // Check if settings are loaded
    final settingsState = context.read<SettingsBloc>().state;
    
    if (!settingsState.aiSummarizationEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enable AI Summarization in Settings first'),
          ),
        );
      }
      return;
    }

    if (!settingsState.openClawEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enable OpenClaw Integration in Settings first'),
          ),
        );
      }
      return;
    }

    setState(() => _isSummarizing = true);

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fetching article and summarizing...'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      
      final summary = await AiService.instance.summarize(widget.article);
      
      if (summary != null && mounted) {
        setState(() => _aiSummary = summary);
        
        // Update article with summary
        final updatedArticle = widget.article.copyWith(summary: summary);
        context.read<ArticleBloc>().add(UpdateArticle(updatedArticle));
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Summary generated!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not generate summary'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSummarizing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMMM d, yyyy');
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: widget.article.imageUrl != null ? 250 : 0,
            pinned: true,
            flexibleSpace: widget.article.imageUrl != null
                ? FlexibleSpaceBar(
                    background: Image.network(
                      widget.article.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, size: 64),
                      ),
                    ),
                  )
                : null,
            actions: [
              // AI Summarize Button
              BlocBuilder<SettingsBloc, SettingsState>(
                builder: (context, state) {
                  if (!state.aiSummarizationEnabled) return const SizedBox();
                  return IconButton(
                    icon: _isSummarizing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    onPressed: _isSummarizing ? null : _summarizeArticle,
                    tooltip: 'Summarize with AI',
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  widget.article.isSaved ? Icons.bookmark : Icons.bookmark_outline,
                ),
                onPressed: () {
                  context.read<ArticleBloc>().add(ToggleArticleSaved(widget.article));
                  Navigator.pop(context);
                },
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  Share.share('${widget.article.title}\n${widget.article.link}');
                },
              ),
              IconButton(
                icon: const Icon(Icons.open_in_browser),
                onPressed: () async {
                  final uri = Uri.parse(widget.article.link);
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
                  widget.article.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (widget.article.author.isNotEmpty) ...[
                      const Icon(Icons.person_outline, size: 16),
                      const SizedBox(width: 4),
                      Text(widget.article.author),
                      const SizedBox(width: 16),
                    ],
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 4),
                    Text(dateFormat.format(widget.article.published)),
                  ],
                ),
                const Divider(height: 32),
                
                // AI Summary Section
                if (_aiSummary != null && _aiSummary!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'AI Summary',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _aiSummary!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                SelectableText(
                  widget.article.content.isNotEmpty 
                      ? _stripHtml(widget.article.content) 
                      : widget.article.summary.isNotEmpty 
                          ? _stripHtml(widget.article.summary) 
                          : 'No content available',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),
                if (widget.article.link.isNotEmpty)
                  Center(
                    child: FilledButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(widget.article.link);
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
