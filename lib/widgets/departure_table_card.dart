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
  State<DepartureTableCard> createState() => DepartureTableCardState();
}

class DepartureTableCardState extends State<DepartureTableCard> {
  List<Departure>? _departures;
  List<Departure> _visibleDepartures = [];
  bool _loading = true;
  int _requestId = 0;
  int _ticks = 0;
  DateTime _now = DateTime.now().toUtc();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _ticks++;
      setState(() => _now = DateTime.now().toUtc());
      _syncVisibleDepartures();
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
    setState(() {
      if (reset) {
        _departures = null;
        _visibleDepartures = [];
      }

      _loading = true;
    });
    try {
      final result = await TransitousApi.fetchDepartures(widget.table);
      if (!mounted || id != _requestId) return;
      setState(() {
        _departures = result;
        _loading = false;
      });
      _syncVisibleDepartures();
    } catch (_) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> refresh() => _load();

  bool _sameDeparture(Departure a, Departure b) =>
      a.departure == b.departure &&
      a.displayName == b.displayName &&
      a.destination == b.destination;

  List<Departure> _desiredDepartures() => (_departures ?? const [])
      .where((d) => d.departure.isAfter(_now))
      .take(widget.table.n)
      .toList();

  void _syncVisibleDepartures() {
    if (!mounted || _departures == null) return;
    final desired = _desiredDepartures();
    if (desired.length == _visibleDepartures.length &&
        desired.asMap().entries.every(
          (entry) => _sameDeparture(entry.value, _visibleDepartures[entry.key]),
        )) {
      return;
    }
    setState(() => _visibleDepartures = desired);
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
        return const SizedBox.shrink();
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

    if (_visibleDepartures.isEmpty) {
      final hasFilter = widget.table.filter.isNotEmpty;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.error, size: 64),
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
        ),
      );
    }

    final signature = _visibleDepartures
        .map((d) => '${d.departure.microsecondsSinceEpoch}:${d.displayName}')
        .join('|');
    return SizedBox(
      height: widget.table.n * 54,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        layoutBuilder: (current, previous) =>
            Stack(fit: StackFit.expand, children: [...previous, ?current]),
        transitionBuilder: (child, animation) {
          final isIncoming = child.key == ValueKey<String>(signature);
          final fade = FadeTransition(opacity: animation, child: child);
          if (!isIncoming) return fade;
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.15),
              end: Offset.zero,
            ).animate(animation),
            child: fade,
          );
        },
        child: Column(
          key: ValueKey(signature),
          children: [
            for (final departure in _visibleDepartures)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: DepartureRow(departure: departure, now: _now),
              ),
          ],
        ),
      ),
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
                                  table.filter.join(', '),
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
                SizedBox(
                  width: 48,
                  height: 48,
                  child: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
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
