import 'package:material_ui/material_ui.dart';

import '../models/departure.dart';
import '../utils/time_utils.dart';

class DepartureRow extends StatelessWidget {
  const DepartureRow({super.key, required this.departure, required this.now});

  final Departure departure;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final d = departure;
    final red = scheme.error;

    final pillBackground = d.routeColor ?? scheme.secondaryContainer;
    final pillForeground = d.routeTextColor ?? scheme.onSecondaryContainer;

    final cancelledDecoration = d.cancelled
        ? TextDecoration.lineThrough
        : TextDecoration.none;

    final timeStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: d.cancelled ? red : null,
      decoration: cancelledDecoration,
      decorationColor: red,
    );

    final destinationStyle = theme.textTheme.bodyLarge?.copyWith(
      color: d.cancelled ? red : null,
      decoration: cancelledDecoration,
      decorationColor: red,
    );

    final scheduledStyle = theme.textTheme.bodySmall?.copyWith(
      color: red,
      fontWeight: FontWeight.w300,
      decoration: TextDecoration.lineThrough,
      decorationColor: red,
    );

    return Row(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: pillBackground,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              d.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: pillForeground,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            d.destination,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: destinationStyle,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                if (d.isDelayed && !d.cancelled)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      formatClock(d.scheduledDeparture, d.timeZone),
                      style: scheduledStyle,
                    ),
                  ),
                // Always shown in the stop's own timezone.
                Text(formatClock(d.departure, d.timeZone), style: timeStyle),
              ],
            ),
            if (!d.cancelled)
              Text(
                timeUntil(d.departure, now),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
