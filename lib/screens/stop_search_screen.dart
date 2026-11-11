import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../models/stop_ref.dart';
import '../services/transitous_api.dart';

/// Pops with the chosen [StopRef]. Used both for adding a table and a filter.
class StopSearchScreen extends StatefulWidget {
  const StopSearchScreen({super.key, required this.title});

  final String title;

  @override
  State<StopSearchScreen> createState() => _StopSearchScreenState();
}

class _StopSearchScreenState extends State<StopSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  int _requestId = 0;

  List<StopRef> _results = const [];
  bool _loading = false;
  Object? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 500),
      () => _search(text.trim()),
    );
  }

  Future<void> _search(String text) async {
    final id = ++_requestId;
    if (text.isEmpty) {
      setState(() {
        _results = const [];
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await TransitousApi.searchStops(text);
      if (!mounted || id != _requestId) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onChanged,
              decoration: const InputDecoration(
                labelText: 'Stop name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: _error != null
                ? Center(
                    child: Text(
                      'Something went wrong. Check your connection.',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  )
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, i) {
                      final stop = _results[i];
                      return ListTile(
                        title: Text(
                          stop.name,
                          style: theme.textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          stop.id,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        onTap: () => Navigator.of(context).pop(stop),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
