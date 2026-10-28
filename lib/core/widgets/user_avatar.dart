import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A circular gradient avatar displaying user initials.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.initials,
    this.size = 46,
    this.imageProvider,
  });

  final String initials;
  final double size;
  final ImageProvider? imageProvider;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: AppColors.avatarGradient,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: imageProvider == null
          ? Text(
              initials,
              style: TextStyle(
                fontSize: size * 0.38,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            )
          : ClipOval(
              child: Image(
                image: imageProvider!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Text(
                  initials,
                  style: TextStyle(
                    fontSize: size * 0.38,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
    );
  }
}
