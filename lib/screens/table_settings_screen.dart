import 'package:material_ui/material_ui.dart';

import '../models/table_config.dart';
import '../services/app_store.dart';

class TableSettingsScreen extends StatefulWidget {
  const TableSettingsScreen({
    super.key,
    required this.table,
    required this.screenIndex,
  });

  final TableConfig table;
  final int screenIndex;

  @override
  State<TableSettingsScreen> createState() => _TableSettingsScreenState();
}

class _TableSettingsScreenState extends State<TableSettingsScreen> {
  static const int _minN = 1;
  static const int _maxN = 30;

  TableConfig get table => widget.table;

  void _setN(int value) {
    setState(() => table.n = value.clamp(_minN, _maxN));
    store.changed();
  }

  Future<void> _addFilterPattern() async {
    final pattern = await showDialog<String>(
      context: context,
      builder: (_) => const _AddFilterPatternDialog(),
    );
    final value = pattern?.trim();
    if (value == null || value.isEmpty || !mounted) return;
    if (table.filter.any(
      (pattern) => pattern.toLowerCase() == value.toLowerCase(),
    )) {
      return;
    }
    setState(() => table.filter.add(value));
    store.changed();
  }

  void _removeFilterPattern(String pattern) {
    setState(() => table.filter.remove(pattern));
    store.changed();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete table?'),
        content: Text('"${table.name}" will be removed from this screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      store.removeTable(widget.screenIndex, table);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grey = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(
        title: Text(table.name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete table',
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Departures shown', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Number of departures displayed in this table.',
            style: theme.textTheme.bodySmall?.copyWith(color: grey),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton.filledTonal(
                icon: const Icon(Icons.remove),
                onPressed: table.n > _minN ? () => _setN(table.n - 1) : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('${table.n}', style: theme.textTheme.headlineSmall),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.add),
                onPressed: table.n < _maxN ? () => _setN(table.n + 1) : null,
              ),
            ],
          ),
          const Divider(height: 40),
          Text('Filter by stop names', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Only connections with a matching destination or passing stop '
            'are shown.',
            style: theme.textTheme.bodySmall?.copyWith(color: grey),
          ),
          const SizedBox(height: 8),
          if (table.filter.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No filter, all departures are shown.',
                style: TextStyle(color: grey),
              ),
            ),
          for (final pattern in table.filter)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.filter_alt_outlined),
              title: Text(pattern),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => _removeFilterPattern(pattern),
              ),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _addFilterPattern,
              icon: const Icon(Icons.add),
              label: const Text('Add name'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddFilterPatternDialog extends StatefulWidget {
  const _AddFilterPatternDialog();

  @override
  State<_AddFilterPatternDialog> createState() =>
      _AddFilterPatternDialogState();
}

class _AddFilterPatternDialogState extends State<_AddFilterPatternDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close([String? value]) {
    // Close the keyboard before the dialog transition; keep the controller
    // alive until this dialog subtree is disposed after that transition.
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add stop name filter'),
    content: TextField(
      controller: _controller,
      autofocus: true,
      decoration: const InputDecoration(
        labelText: 'Stop name includes',
        hintText: 'For example, Main Street',
      ),
      onSubmitted: (value) => _close(value),
    ),
    actions: [
      TextButton(onPressed: _close, child: const Text('Cancel')),
      FilledButton(
        onPressed: () => _close(_controller.text),
        child: const Text('Add'),
      ),
    ],
  );
}
