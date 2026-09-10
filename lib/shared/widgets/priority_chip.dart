import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class PriorityChip extends StatelessWidget {
  final String priority;
  final bool compact;

  const PriorityChip({super.key, required this.priority, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(priority);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact) ...[
            Icon(config.icon, size: 12, color: config.color),
            const SizedBox(width: 4),
          ],
          Text(
            config.label,
            style: AppTextStyles.labelSmall.copyWith(
              color: config.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _PriorityConfig _getConfig(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
      case 'critical':
        return _PriorityConfig(
          label: priority == 'critical' ? 'Critical' : 'High Priority',
          color: AppColors.priorityHigh,
          bg: AppColors.priorityHigh.withOpacity(0.12),
          icon: Icons.flag_rounded,
        );
      case 'medium':
        return _PriorityConfig(
          label: 'Medium',
          color: AppColors.priorityMedium,
          bg: AppColors.priorityMedium.withOpacity(0.12),
          icon: Icons.flag_rounded,
        );
      case 'low':
        return _PriorityConfig(
          label: 'Low',
          color: AppColors.priorityLow,
          bg: AppColors.priorityLow.withOpacity(0.12),
          icon: Icons.flag_outlined,
        );
      case 'productive':
        return _PriorityConfig(
          label: 'Productive',
          color: AppColors.primary,
          bg: AppColors.primary.withOpacity(0.12),
          icon: Icons.bolt_rounded,
        );
      default:
        return _PriorityConfig(
          label: priority,
          color: AppColors.textSecondary,
          bg: AppColors.borderLight,
          icon: Icons.label_rounded,
        );
    }
  }
}

class _PriorityConfig {
  final String label;
  final Color color;
  final Color bg;
  final IconData icon;
  const _PriorityConfig({
    required this.label,
    required this.color,
    required this.bg,
    required this.icon,
  });
}

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        config.label,
        style: AppTextStyles.labelSmall.copyWith(
          color: config.color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  _PriorityConfig _getStatusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return _PriorityConfig(
          label: 'Active',
          color: AppColors.statusActive,
          bg: AppColors.statusActive.withOpacity(0.12),
          icon: Icons.circle,
        );
      case 'completed':
      case 'done':
        return _PriorityConfig(
          label: status == 'done' ? 'Done' : 'Completed',
          color: AppColors.statusDone,
          bg: AppColors.statusDone.withOpacity(0.12),
          icon: Icons.check_circle,
        );
      case 'pending':
      case 'paused':
        return _PriorityConfig(
          label: status == 'pending' ? 'Pending' : 'Paused',
          color: AppColors.statusPending,
          bg: AppColors.statusPending.withOpacity(0.12),
          icon: Icons.pause_circle,
        );
      case 'overdue':
      case 'cancelled':
        return _PriorityConfig(
          label: status == 'overdue' ? 'Overdue' : 'Cancelled',
          color: AppColors.statusOverdue,
          bg: AppColors.statusOverdue.withOpacity(0.12),
          icon: Icons.cancel,
        );
      case 'inprogress':
      case 'in_progress':
      case 'review':
        return _PriorityConfig(
          label: 'In Progress',
          color: AppColors.accentBlue,
          bg: AppColors.accentBlue.withOpacity(0.12),
          icon: Icons.hourglass_empty,
        );
      default:
        return _PriorityConfig(
          label: status,
          color: AppColors.textSecondary,
          bg: AppColors.borderLight,
          icon: Icons.circle,
        );
    }
  }
}
