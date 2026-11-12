import 'package:material_ui/material_ui.dart';

import '../models/table_config.dart';
import '../services/app_store.dart';
import 'departure_table_card.dart';

/// One page of the PageView: the reorderable list of tables of a screen.
class ScreenPage extends StatefulWidget {
  const ScreenPage({super.key, required this.screenIndex});

  final int screenIndex;

  @override
  State<ScreenPage> createState() => _ScreenPageState();
}

class _ScreenPageState extends State<ScreenPage> {
  final Map<TableConfig, GlobalKey<DepartureTableCardState>> _tableKeys = {};

  Future<void> _refreshTables() async {
    final tables = store.tablesOf(widget.screenIndex);
    await Future.wait([
      for (final table in tables)
        _tableKeys[table]?.currentState?.refresh() ?? Future<void>.value(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final tables = store.tablesOf(widget.screenIndex);

        if (tables.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.table_rows_rounded,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  'No tables on this screen yet',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap + to add one',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshTables,
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            buildDefaultDragHandles: false,
            // Each table already provides its own rounded, elevated Material.
            // The default proxy adds another Material around the full list
            // item (including its spacing), creating a square shadow frame.
            proxyDecorator: (child, index, animation) => child,
            itemCount: tables.length,
            onReorderItem: (oldIndex, newIndex) =>
                store.reorder(widget.screenIndex, oldIndex, newIndex),
            itemBuilder: (context, i) {
              final table = tables[i];
              final tableKey = _tableKeys.putIfAbsent(
                table,
                () => GlobalKey<DepartureTableCardState>(),
              );
              return ReorderableDelayedDragStartListener(
                key: ObjectKey(table),
                index: i,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: DepartureTableCard(
                    key: tableKey,
                    table: table,
                    screenIndex: widget.screenIndex,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
