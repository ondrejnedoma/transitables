import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/departure.dart';
import '../models/stop_ref.dart';
import '../models/table_config.dart';

class TransitousApi {
  TransitousApi._();

  static const _host = 'api.transitous.org';
  static const _filterWindowSeconds = 86400; // 1 day
  static final http.Client _client = http.Client();
  static String _userAgent =
      'TransiTables/unknownVersion (https://github.com/ondrejnedoma)';

  static void setAppVersion(String version) {
    _userAgent = 'TransiTables/$version (https://github.com/ondrejnedoma)';
  }

  static Map<String, String> get _headers => {'User-Agent': _userAgent};

  /// GET /api/v1/geocode?text=...  (only STOP results can be used for departures)
  static Future<List<StopRef>> searchStops(String text) async {
    final res = await _client.get(
      Uri.https(_host, '/api/v1/geocode', {'text': text}),
      headers: _headers,
    );
    if (res.statusCode != 200) {
      throw Exception('Search failed (${res.statusCode})');
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
    return data
        .whereType<Map<String, dynamic>>()
        .where((e) => e['type'] == 'STOP')
        .map((e) => StopRef(id: e['id'] as String, name: e['name'] as String))
        .toList();
  }

  static Future<List<Departure>> fetchDepartures(TableConfig table) async {
    final params = <String, String>{
      'stopId': table.id,
      'fetchStops': 'true',
      'window': '$_filterWindowSeconds',
    };

    final res = await _client.get(
      Uri.https(_host, '/api/v6/stoptimes', params),
      headers: _headers,
    );
    if (res.statusCode != 200) {
      throw Exception('Could not load departures (${res.statusCode})');
    }

    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    var departures =
        ((body['stopTimes'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(Departure.fromJson)
            .toList()
          ..sort((a, b) => a.departure.compareTo(b.departure));

    final hasFilter = table.filter.isNotEmpty;
    if (hasFilter) {
      final ids = table.filter.map((s) => s.id).toSet();
      final names = table.filter.map((s) => s.name).toSet();
      departures = departures
          .where(
            (d) =>
                d.passingStopIds.any(ids.contains) ||
                d.passingStopNames.any(names.contains),
          )
          .toList();
    }

    return departures;
  }
}
