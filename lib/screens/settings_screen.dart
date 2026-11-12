import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/app_store.dart';
import '../services/transitous_api.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _motisLink = TapGestureRecognizer()
    ..onTap = () =>
        launchUrl(Uri.parse('https://github.com/motis-project/motis'));
  final _transitousLink = TapGestureRecognizer()
    ..onTap = () => launchUrl(Uri.parse('https://transitous.org'));
  final _sourcesLink = TapGestureRecognizer()
    ..onTap = () => launchUrl(Uri.parse('https://transitous.org/sources/'));

  @override
  void dispose() {
    _motisLink.dispose();
    _transitousLink.dispose();
    _sourcesLink.dispose();
    super.dispose();
  }

  String get _themeLabel => switch (store.themeMode) {
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
    _ => 'Follow system',
  };

  Future<void> _chooseTheme() async {
    final selected = await showDialog<ThemeMode>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Theme'),
        children: [
          RadioGroup<ThemeMode>(
            groupValue: store.themeMode,
            onChanged: (value) => Navigator.pop(context, value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final option in [
                  (ThemeMode.system, 'Follow system'),
                  (ThemeMode.light, 'Light'),
                  (ThemeMode.dark, 'Dark'),
                ])
                  RadioListTile<ThemeMode>(
                    value: option.$1,
                    title: Text(option.$2),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (selected != null) {
      store.setThemeMode(selected);
      if (mounted) setState(() {});
    }
  }

  Future<void> _editInstance() async {
    final value = await showDialog<String>(
      context: context,
      builder: (_) => _MotisInstanceDialog(initialUrl: store.apiBaseUrl),
    );
    if (value == null || !mounted) return;
    try {
      final normalized = TransitousApi.normalizeBaseUrl(value);
      store.setApiBaseUrl(normalized);
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('MOTIS instance updated.')));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not use instance: $error')),
        );
      }
    }
  }

  Future<void> _backup() async {
    try {
      final bytes = Uint8List.fromList(
        utf8.encode(
          const JsonEncoder.withIndent('  ').convert(store.exportData()),
        ),
      );
      final savedPath = await FileSaver.instance.saveAs(
        name: 'transitables-${DateTime.now().millisecondsSinceEpoch}',
        bytes: bytes,
        fileExtension: 'json',
        mimeType: MimeType.other,
        customMimeType: 'application/json',
      );
      if (savedPath != null && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Backup saved.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create backup: $error')),
        );
      }
    }
  }

  Future<void> _restore() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'JSON', extensions: ['json']),
      ],
    );
    if (file == null) return;
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (!mounted) return;
      if (decoded is! Map<String, dynamic> || decoded['screens'] == null) {
        throw const FormatException('This file is not a TransiTables backup.');
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Restore backup?'),
          content: const Text('This replaces the current settings and tables.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Restore'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await store.restoreData(decoded);
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Backup restored.')));
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not restore backup: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grey = theme.colorScheme.onSurfaceVariant;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          ListTile(
            leading: const Icon(Icons.color_lens_outlined),
            title: const Text('Theme'),
            subtitle: Text(_themeLabel, style: TextStyle(color: grey)),
            onTap: _chooseTheme,
          ),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('Backup'),
            subtitle: Text(
              'Export settings and tables to a JSON file.',
              style: TextStyle(color: grey),
            ),
            onTap: _backup,
          ),
          ListTile(
            leading: const Icon(Icons.settings_backup_restore_outlined),
            title: const Text('Restore'),
            subtitle: Text(
              'Import settings and tables from a JSON file.',
              style: TextStyle(color: grey),
            ),
            onTap: _restore,
          ),
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: const Text('MOTIS instance'),
            subtitle: Text(store.apiBaseUrl, style: TextStyle(color: grey)),
            onTap: _editInstance,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 24, 24),
            child: Text.rich(
              TextSpan(
                style: theme.textTheme.bodySmall?.copyWith(color: grey),
                children: [
                  const TextSpan(text: 'A '),
                  TextSpan(
                    text: 'MOTIS',
                    style: _linkStyle(theme),
                    recognizer: _motisLink,
                  ),
                  const TextSpan(
                    text: ' instance for all the data related to public transport. By default, ',
                  ),
                  TextSpan(
                    text: 'Transitous',
                    style: _linkStyle(theme),
                    recognizer: _transitousLink,
                  ),
                  const TextSpan(text: ' is used with '),
                  TextSpan(
                    text: 'sources, licenses, and attributions',
                    style: _linkStyle(theme),
                    recognizer: _sourcesLink,
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _linkStyle(ThemeData theme) => TextStyle(
    color: theme.colorScheme.primary,
    decoration: TextDecoration.underline,
  );
}

class _MotisInstanceDialog extends StatefulWidget {
  const _MotisInstanceDialog({required this.initialUrl});

  final String initialUrl;

  @override
  State<_MotisInstanceDialog> createState() => _MotisInstanceDialogState();
}

class _MotisInstanceDialogState extends State<_MotisInstanceDialog> {
  late final TextEditingController _controller;
  bool _checking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close([String? value]) {
    // Dismiss the keyboard before the dialog route begins its exit animation.
    // The controller remains alive until this dialog is actually disposed.
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(value);
  }

  Future<void> _save() async {
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final normalized = TransitousApi.normalizeBaseUrl(_controller.text);
      final initialUrl = TransitousApi.normalizeBaseUrl(widget.initialUrl);
      if (normalized != initialUrl) {
        await TransitousApi.checkHealth(normalized);
      }
      if (mounted) _close(normalized);
    } catch (error) {
      if (mounted) {
        setState(() {
          _checking = false;
          _error = 'Could not use this instance: $error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('MOTIS instance'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'Instance URL',
            hintText: 'https://api.transitous.org',
          ),
          onSubmitted: (_) => _save(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    ),
    actions: [
      TextButton(onPressed: _close, child: const Text('Cancel')),
      FilledButton(
        onPressed: _checking ? null : _save,
        child: _checking
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Save'),
      ),
    ],
  );
}
