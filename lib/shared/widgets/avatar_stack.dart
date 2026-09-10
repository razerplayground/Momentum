import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Stack of avatar circles like in reference images
class AvatarStack extends StatelessWidget {
  final List<String> names;
  final List<int>? colorValues;
  final double size;
  final double overlap;
  final int maxVisible;

  const AvatarStack({
    super.key,
    required this.names,
    this.colorValues,
    this.size = 28,
    this.overlap = 0.35,
    this.maxVisible = 3,
  });

  @override
  Widget build(BuildContext context) {
    final visible = names.take(maxVisible).toList();
    final remaining = names.length - maxVisible;
    final itemWidth = size * (1 - overlap);

    return SizedBox(
      width: itemWidth * visible.length + (remaining > 0 ? size : 0),
      height: size,
      child: Stack(
        children: [
          ...visible.asMap().entries.map((entry) {
            final i = entry.key;
            final name = entry.value;
            final color = colorValues != null && i < colorValues!.length
                ? Color(colorValues![i])
                : AppColors.workspaceColors[i % AppColors.workspaceColors.length];
            return Positioned(
              left: i * itemWidth,
              child: _AvatarCircle(
                name: name,
                color: color,
                size: size,
              ),
            );
          }),
          if (remaining > 0)
            Positioned(
              left: visible.length * itemWidth,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '+$remaining',
                    style: AppTextStyles.labelSmall.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final String name;
  final Color color;
  final double size;

  const _AvatarCircle({
    required this.name,
    required this.color,
    required this.size,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.33,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Single employee avatar with optional label
class EmployeeAvatar extends StatelessWidget {
  final String name;
  final int colorValue;
  final double size;
  final String? avatarUrl;

  const EmployeeAvatar({
    super.key,
    required this.name,
    required this.colorValue,
    this.size = 40,
    this.avatarUrl,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color(colorValue),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.36,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
