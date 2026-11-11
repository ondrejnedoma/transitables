import 'package:material_ui/material_ui.dart';

import '../models/stop_ref.dart';
import '../models/table_config.dart';
import '../services/app_store.dart';
import 'stop_search_screen.dart';

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

  Future<void> _addFilterStop() async {
    final stop = await Navigator.of(context).push<StopRef>(
      MaterialPageRoute(
        builder: (_) => const StopSearchScreen(title: 'Add filter stop'),
      ),
    );
    if (stop == null || !mounted) return;
    if (table.filter.any((s) => s.id == stop.id)) return;
    setState(() => table.filter.add(stop));
    store.changed();
  }

  void _removeFilterStop(StopRef stop) {
    setState(() => table.filter.remove(stop));
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
          Text('Filter by stops', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Only connections passing through at least one of these stops '
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
          for (final stop in table.filter)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.filter_alt_outlined),
              title: Text(stop.name),
              subtitle: Text(
                stop.id,
                style: theme.textTheme.bodySmall?.copyWith(color: grey),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => _removeFilterStop(stop),
              ),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _addFilterStop,
              icon: const Icon(Icons.add),
              label: const Text('Add stop'),
            ),
          ),
        ],
      ),
    );
  }
}
