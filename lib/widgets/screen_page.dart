import 'package:material_ui/material_ui.dart';

import '../services/app_store.dart';
import 'departure_table_card.dart';

/// One page of the PageView: the reorderable list of tables of a screen.
class ScreenPage extends StatelessWidget {
  const ScreenPage({super.key, required this.screenIndex});

  final int screenIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final tables = store.tablesOf(screenIndex);

        if (tables.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.departure_board,
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

        return ReorderableListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          // Long-press anywhere on a table to drag it.
          buildDefaultDragHandles: false,
          itemCount: tables.length,
          onReorderItem: (oldIndex, newIndex) =>
              store.reorder(screenIndex, oldIndex, newIndex),
          itemBuilder: (context, i) {
            final table = tables[i];
            return ReorderableDelayedDragStartListener(
              key: ObjectKey(table),
              index: i,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: DepartureTableCard(
                  table: table,
                  screenIndex: screenIndex,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
