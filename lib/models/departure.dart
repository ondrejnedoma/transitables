import 'package:material_ui/material_ui.dart';

class Departure {
  Departure({
    required this.displayName,
    required this.destination,
    required this.routeColor,
    required this.routeTextColor,
    required this.departure,
    required this.scheduledDeparture,
    required this.timeZone,
    required this.cancelled,
    required this.passingStopIds,
  });

  final String displayName;
  final String destination;
  final Color? routeColor;
  final Color? routeTextColor;

  /// Both in UTC.
  final DateTime departure;
  final DateTime scheduledDeparture;

  /// IANA name of the timezone of the stop, e.g. "Europe/Prague".
  final String timeZone;
  final bool cancelled;

  /// stopId + parentId of every upcoming stop and the destination.
  final Set<String> passingStopIds;

  bool get isDelayed => !departure.isAtSameMomentAs(scheduledDeparture);

  factory Departure.fromJson(Map<String, dynamic> json) {
    final place = json['place'] as Map<String, dynamic>;
    final actualRaw =
        (place['departure'] ?? place['scheduledDeparture']) as String;
    final scheduledRaw =
        (place['scheduledDeparture'] ?? place['departure']) as String;

    final ids = <String>{};
    void collect(dynamic stop) {
      if (stop is! Map) return;
      final stopId = stop['stopId'];
      final parentId = stop['parentId'];
      if (stopId is String) ids.add(stopId);
      if (parentId is String) ids.add(parentId);
    }

    for (final s in (json['nextStops'] as List?) ?? const []) {
      collect(s);
    }
    collect(json['tripTo']);

    final headsign = json['headsign'] as String?;
    final tripToName = (json['tripTo'] as Map?)?['name'] as String?;

    return Departure(
      displayName:
          (json['displayName'] ??
                  json['routeShortName'] ??
                  json['tripShortName'] ??
                  '?')
              as String,
      destination: (headsign != null && headsign.isNotEmpty)
          ? headsign
          : (tripToName ?? ''),
      routeColor: _parseColor(json['routeColor']),
      routeTextColor: _parseColor(json['routeTextColor']),
      departure: DateTime.parse(actualRaw).toUtc(),
      scheduledDeparture: DateTime.parse(scheduledRaw).toUtc(),
      timeZone: (place['tz'] as String?) ?? 'UTC',
      cancelled:
          json['cancelled'] == true ||
          json['tripCancelled'] == true ||
          place['cancelled'] == true,
      passingStopIds: ids,
    );
  }

  static Color? _parseColor(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    final hex = value.replaceFirst('#', '');
    final parsed = int.tryParse(hex.length == 6 ? 'FF$hex' : hex, radix: 16);
    return parsed == null ? null : Color(parsed);
  }
}
