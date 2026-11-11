import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../models/departure.dart';
import '../models/table_config.dart';
import '../screens/table_settings_screen.dart';
import '../services/transitous_api.dart';
import 'departure_row.dart';

class DepartureTableCard extends StatefulWidget {
  const DepartureTableCard({
    super.key,
    required this.table,
    required this.screenIndex,
  });

  final TableConfig table;
  final int screenIndex;

  @override
  State<DepartureTableCard> createState() => _DepartureTableCardState();
}

class _DepartureTableCardState extends State<DepartureTableCard> {
  List<Departure>? _departures;
  bool _loading = true;
  int _requestId = 0;
  int _ticks = 0;
  DateTime _now = DateTime.now().toUtc();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    // Every second: refresh countdowns. Every 30 s: refetch.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _ticks++;
      setState(() => _now = DateTime.now().toUtc());
      if (_ticks % 30 == 0) _load();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    final id = ++_requestId;
    if (reset) {
      setState(() {
        _departures = null;
        _loading = true;
      });
    }
    try {
      final result = await TransitousApi.fetchDepartures(widget.table);
      if (!mounted || id != _requestId) return;
      setState(() {
        _departures = result;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TableSettingsScreen(
          table: widget.table,
          screenIndex: widget.screenIndex,
        ),
      ),
    );
    if (mounted) _load(reset: true);
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final grey = theme.colorScheme.onSurfaceVariant;

    if (_departures == null) {
      if (_loading) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.cloud_off, color: grey),
            const SizedBox(height: 8),
            Text("Couldn't load departures", style: TextStyle(color: grey)),
            TextButton(
              onPressed: () => _load(reset: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Hide departures that already left between two refetches.
    final shown = _departures!
        .where((d) => d.departure.isAfter(_now))
        .take(widget.table.n)
        .toList();

    if (shown.isEmpty) {
      final hasFilter = widget.table.filter.isNotEmpty;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            const Text('😕', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? "Your filters don't match any results"
                  : 'No upcoming departures',
              textAlign: TextAlign.center,
              style: TextStyle(color: grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (final d in shown)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: DepartureRow(departure: d, now: _now),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final table = widget.table;

    return Material(
      elevation: 3,
      color: scheme.surfaceContainerHigh,
      shadowColor: scheme.shadow,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          table.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (table.filter.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.filter_alt_outlined,
                                size: 16,
                                color: scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  table.filter.map((s) => s.name).join(', '),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit table',
                  onPressed: _openSettings,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _buildBody(context),
            ),
          ],
        ),
      ),
    );
  }
}
