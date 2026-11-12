import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/departure.dart';
import '../models/stop_ref.dart';
import '../models/table_config.dart';

class TransitousApi {
  TransitousApi._();

  static const defaultBaseUrl = 'https://api.transitous.org';
  static String _baseUrl = defaultBaseUrl;
  static const _filterWindowSeconds = 86400; // 1 day
  static final http.Client _client = http.Client();
  static String _userAgent =
      'TransiTables/unknownVersion (https://github.com/ondrejnedoma)';

  static void setAppVersion(String version) {
    _userAgent = 'TransiTables/$version (https://github.com/ondrejnedoma)';
  }

  static Map<String, String> get _headers => {'User-Agent': _userAgent};

  static String normalizeBaseUrl(String value) {
    final uri = Uri.parse(value.trim());
    if (!uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.query.isNotEmpty ||
        uri.fragment.isNotEmpty) {
      throw const FormatException('Enter a valid HTTP or HTTPS URL.');
    }
    return uri
        .replace(path: uri.path.replaceFirst(RegExp(r'/+$'), ''))
        .toString();
  }

  static void setBaseUrl(String value) {
    _baseUrl = normalizeBaseUrl(value);
  }

  static Future<void> checkHealth(String value) async {
    final normalized = normalizeBaseUrl(value);
    final res = await _client
        .get(_endpointFor(normalized, '/api/v1/health'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw Exception('Health check failed (${res.statusCode})');
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    if (body is! Map || body['rt'] != true || body['gbfs'] != true) {
      throw const FormatException(
        'The MOTIS instance is missing required realtime or GBFS support.',
      );
    }
  }

  static Uri _endpoint(String path, [Map<String, String>? query]) {
    return _endpointFor(_baseUrl, path, query);
  }

  static Uri _endpointFor(
    String baseUrl,
    String path, [
    Map<String, String>? query,
  ]) {
    final base = Uri.parse(baseUrl);
    return base.replace(
      path: '${base.path.replaceFirst(RegExp(r'/+$'), '')}$path',
      queryParameters: query,
    );
  }

  /// GET /api/v1/geocode?text=...  (only STOP results can be used for departures)
  static Future<List<StopRef>> searchStops(String text) async {
    final res = await _client.get(
      _endpoint('/api/v1/geocode', {'text': text}),
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
      _endpoint('/api/v6/stoptimes', params),
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
      final patterns = table.filter
          .map((pattern) => pattern.trim().toLowerCase())
          .where((pattern) => pattern.isNotEmpty)
          .toList();
      departures = departures
          .where(
            (d) => patterns.any(
              (pattern) =>
                  d.destination.toLowerCase().contains(pattern) ||
                  d.passingStopNames.any(
                    (name) => name.toLowerCase().contains(pattern),
                  ),
            ),
          )
          .toList();
    }

    return departures;
  }
}
