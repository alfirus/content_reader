import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/settings/settings_bloc.dart';
import '../../core/api/api_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return ListView(
            children: [
              // Appearance Section
              _sectionHeader('Appearance'),
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Enable dark theme'),
                value: state.isDarkMode,
                onChanged: (_) {
                  context.read<SettingsBloc>().add(ToggleDarkMode());
                },
                secondary: Icon(
                  state.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                ),
              ),
              const Divider(),
              
              // AI Features Section
              _sectionHeader('AI Features'),
              SwitchListTile(
                title: const Text('AI Summarization'),
                subtitle: const Text('Summarize articles using AI'),
                value: state.aiSummarizationEnabled,
                onChanged: (_) {
                  context.read<SettingsBloc>().add(ToggleAiSummarization());
                },
                secondary: const Icon(Icons.summarize),
              ),
              SwitchListTile(
                title: const Text('OpenClaw Integration'),
                subtitle: const Text('Use local OpenClaw for AI features'),
                value: state.openClawEnabled,
                onChanged: (_) {
                  context.read<SettingsBloc>().add(ToggleOpenClawIntegration());
                },
                secondary: const Icon(Icons.smart_toy),
              ),
              if (state.openClawEnabled)
                ListTile(
                  leading: const Icon(Icons.link),
                  title: const Text('OpenClaw URL'),
                  subtitle: Text(state.openClawUrl),
                  onTap: () => _showOpenClawUrlDialog(context, state.openClawUrl),
                ),
              const Divider(),
              
              // Background Section
              _sectionHeader('Background'),
              SwitchListTile(
                title: const Text('Background Refresh'),
                subtitle: const Text('Automatically fetch new articles'),
                value: state.backgroundRefreshEnabled,
                onChanged: (_) {
                  context.read<SettingsBloc>().add(ToggleBackgroundRefresh());
                },
                secondary: const Icon(Icons.refresh),
              ),
              const Divider(),
              
              // API Section
              _sectionHeader('API'),
              ListTile(
                leading: const Icon(Icons.key),
                title: const Text('API Key'),
                subtitle: const Text('Tap to view API key'),
                onTap: () async {
                  final apiKey = ApiService().apiKey;
                  if (apiKey != null && context.mounted) {
                    _showApiKeyDialog(context, apiKey);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Regenerate API Key'),
                subtitle: const Text('Generate a new API key'),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Regenerate API Key?'),
                      content: const Text(
                        'This will invalidate your current API key. '
                        'You will need to update it in any apps using it.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Regenerate'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );

                    final newKey = await ApiService().regenerateApiKey();
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                      _showApiKeyDialog(context, newKey);
                    }
                  }
                },
              ),
              const Divider(),
              
              // About Section
              _sectionHeader('About'),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About'),
                subtitle: const Text('Content Reader v1.0.0'),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Content Reader',
                    applicationVersion: '1.0.0',
                    applicationLegalese: '© 2026 Alfirus Ahmad',
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  void _showApiKeyDialog(BuildContext context, String apiKey) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Use this key to authenticate API requests:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                apiKey,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: apiKey));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('API key copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showOpenClawUrlDialog(BuildContext context, String currentUrl) {
    final controller = TextEditingController(text: currentUrl);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('OpenClaw URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Gateway URL',
            hintText: 'http://localhost:18789',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<SettingsBloc>().add(UpdateOpenClawUrl(controller.text));
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
