import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../core/opml/opml_service.dart';

class OpmlPage extends StatefulWidget {
  const OpmlPage({super.key});

  @override
  State<OpmlPage> createState() => _OpmlPageState();
}

class _OpmlPageState extends State<OpmlPage> {
  bool _isProcessing = false;
  String? _resultMessage;
  bool _isSuccess = false;

  Future<void> _exportOpml() async {
    setState(() {
      _isProcessing = true;
      _resultMessage = null;
    });

    try {
      final file = await OpmlService.instance.saveOpmlToFile();
      
      // Share the file
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Content Reader Feeds Export',
      );
      
      setState(() {
        _isProcessing = false;
        _isSuccess = true;
        _resultMessage = 'Exported successfully! ${file.path.split('/').last}';
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _isSuccess = false;
        _resultMessage = 'Export failed: $e';
      });
    }
  }

  Future<void> _importOpml() async {
    setState(() {
      _isProcessing = true;
      _resultMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['opml', 'xml'],
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      final filePath = result.files.first.path;
      if (filePath == null) {
        setState(() {
          _isProcessing = false;
          _isSuccess = false;
          _resultMessage = 'No file selected';
        });
        return;
      }

      final importResult = await OpmlService.instance.importOpml(filePath);
      
      setState(() {
        _isProcessing = false;
        _isSuccess = importResult.success;
        _resultMessage = importResult.toString();
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _isSuccess = false;
        _resultMessage = 'Import failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OPML Import/Export'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Export Feeds',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Export all your feeds and categories to an OPML file. '
                      'You can use this file to backup your feeds or import them into another RSS reader.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _isProcessing ? null : _exportOpml,
                      icon: _isProcessing && _resultMessage == null
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download),
                      label: const Text('Export to OPML'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Import Feeds',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Import feeds from an OPML file. Duplicate feeds (same URL) will be skipped.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _isProcessing ? null : _importOpml,
                      icon: _isProcessing && _resultMessage == null
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload),
                      label: const Text('Import from OPML'),
                      variant: FilledButtonVariant.tonal,
                    ),
                  ],
                ),
              ),
            ),
            if (_resultMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isSuccess
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isSuccess ? Colors.green : Colors.red,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSuccess ? Icons.check_circle : Icons.error,
                      color: _isSuccess ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _resultMessage!,
                        style: TextStyle(
                          color: _isSuccess ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Spacer(),
            Text(
              'OPML (Outline Processor Markup Language) is a standard format for exchanging feed lists between RSS readers.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
