import 'package:timezone/timezone.dart' as tz;

/// Formats a UTC instant as HH:mm in the given IANA timezone,
/// regardless of where the device is.
String formatClock(DateTime utc, String timeZoneName) {
  tz.Location location;
  try {
    location = tz.getLocation(timeZoneName);
  } catch (_) {
    location = tz.UTC;
  }
  final t = tz.TZDateTime.from(utc, location);
  return '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';
}

/// "5 mins" / "1 min" / "39 s". Computed from absolute instants,
/// so it is correct no matter the device or stop timezone.
String timeUntil(DateTime departureUtc, DateTime nowUtc) {
  final seconds = departureUtc.difference(nowUtc).inSeconds;
  if (seconds <= 0) return 'now';
  if (seconds <= 60) return '$seconds s';
  final minutes = (seconds / 60).ceil() - 1;
  if (seconds >= 60 * 60) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) return '$hours h';
    return '$hours h $remainingMinutes min';
  }
  return minutes == 1 ? '1 min' : '$minutes mins';
}
