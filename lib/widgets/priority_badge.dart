// ============================================================
// WIDGET: BADGE PRIORITAS
// Chip kecil berwarna (merah/amber/abu) + label bahasa Indonesia.
// ============================================================
import 'package:flutter/material.dart';
import 'package:premium_todo/models/task_priority.dart';

class PriorityBadge extends StatelessWidget {
  final TaskPriority priority;
  final bool compact;

  const PriorityBadge({super.key, required this.priority, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final color = Color(priority.colorValue);

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(priority.iconName == 'keyboard_double_arrow_up'
              ? Icons.keyboard_double_arrow_up_rounded
              : priority.iconName == 'priority_high'
                  ? Icons.priority_high_rounded
                  : Icons.low_priority_rounded,
              size: compact ? 12 : 14,
              color: color),
          const SizedBox(width: 4),
          Text(
            priority.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
