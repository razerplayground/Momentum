import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../data/services/api_service.dart';

class StorageScreen extends ConsumerStatefulWidget {
  const StorageScreen({super.key});

  @override
  ConsumerState<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends ConsumerState<StorageScreen> {
  final _filenameController = TextEditingController();
  XFile? _selectedFile;
  Uint8List? _selectedBytes;
  bool _uploading = false;
  bool _downloading = false;
  String? _message;
  String? _error;

  @override
  void dispose() {
    _filenameController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final file = await openFile();
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw const FormatException('The selected file could not be read.');
      }

      setState(() {
        _selectedFile = file;
        _selectedBytes = bytes;
        _filenameController.text = file.name;
        _message = null;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not select file: $e';
        _message = null;
      });
    }
  }

  Future<void> _uploadFile() async {
    final file = _selectedFile;
    final bytes = _selectedBytes;
    if (file == null || bytes == null) {
      setState(() {
        _error = 'Choose a file before uploading.';
        _message = null;
      });
      return;
    }

    setState(() {
      _uploading = true;
      _error = null;
      _message = null;
    });
    try {
      final response = await ref
          .read(apiServiceProvider)
          .uploadStorageFile(file.name, bytes);
      final storedFilename = _findFilename(response);
      if (!mounted) return;
      setState(() {
        if (storedFilename != null) {
          _filenameController.text = storedFilename;
        }
        _message = storedFilename == null
            ? 'Uploaded ${file.name}. Confirm the stored filename below before downloading.'
            : 'Uploaded ${file.name} successfully.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Upload failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
  }

  String? _findFilename(dynamic value) {
    if (value is! Map) return null;
    for (final key in const ['filename', 'fileName', 'storedFilename']) {
      final filename = value[key]?.toString().trim();
      if (filename != null && filename.isNotEmpty) return filename;
    }
    for (final key in const ['data', 'file', 'result']) {
      final nested = _findFilename(value[key]);
      if (nested != null) return nested;
    }
    return null;
  }

  Future<void> _downloadFile() async {
    final filename = _filenameController.text.trim();
    if (filename.isEmpty) {
      setState(() {
        _error = 'Enter the stored filename to download.';
        _message = null;
      });
      return;
    }

    setState(() {
      _downloading = true;
      _error = null;
      _message = null;
    });
    try {
      final bytes =
          await ref.read(apiServiceProvider).downloadStorageFile(filename);
      final directory = await getApplicationDocumentsDirectory();
      final safeFilename = filename
          .split(RegExp(r'[/\\]'))
          .last
          .replaceAll(RegExp(r'[<>:"|?*\x00-\x1F]'), '_');
      final destination =
          safeFilename.isEmpty ? 'downloaded_file' : safeFilename;
      final savedFile = File(
        '${directory.path}${Platform.pathSeparator}$destination',
      );
      await savedFile.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      setState(() {
        _message = 'Downloaded to ${savedFile.path}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Download failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _downloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Storage'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Upload and retrieve receipts, avatars, and attachments.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Upload a file', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Choose a file from your device, then upload it securely.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _uploading || _downloading ? null : _pickFile,
                    icon: const Icon(Icons.attach_file),
                    label: Text(_selectedFile?.name ?? 'Choose file'),
                  ),
                  if (_selectedFile != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${_selectedBytes!.length} bytes',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _uploading || _downloading ? null : _uploadFile,
                    icon: _uploading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload_outlined),
                    label: Text(_uploading ? 'Uploading...' : 'Upload'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Download a stored file',
                      style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the filename returned by the upload service. The file will be saved to your app documents.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _filenameController,
                    enabled: !_uploading && !_downloading,
                    decoration: const InputDecoration(
                      labelText: 'Stored filename',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.insert_drive_file_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed:
                        _uploading || _downloading ? null : _downloadFile,
                    icon: _downloading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download_outlined),
                    label: Text(_downloading ? 'Downloading...' : 'Download'),
                  ),
                ],
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _StatusMessage(message: _error!, isError: true),
          ],
          if (_message != null) ...[
            const SizedBox(height: 12),
            _StatusMessage(message: _message!),
          ],
        ],
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? Theme.of(context).colorScheme.error : Colors.green;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(message, style: TextStyle(color: color)),
      ),
    );
  }
}
