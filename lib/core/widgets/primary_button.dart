import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// A gradient primary action with optional leading and trailing content.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.leading,
    this.trailing,
    this.size = PrimaryButtonSize.large,
    this.disabled = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final Widget? trailing;
  final PrimaryButtonSize size;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final borderRadius = size == PrimaryButtonSize.small ? 12.0 : 16.0;
    final height = size == PrimaryButtonSize.small
        ? 34.0
        : size == PrimaryButtonSize.medium
        ? 46.0
        : 52.0;
    final fontSize = size == PrimaryButtonSize.small ? 12.5 : 15.0;
    final padding = size == PrimaryButtonSize.small
        ? const EdgeInsets.symmetric(horizontal: 12)
        : const EdgeInsets.symmetric(horizontal: 18);

    final button = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.brand600.withValues(alpha: 0.32),
            blurRadius: AppSpacing.brandShadowBlur,
            offset: const Offset(0, AppSpacing.brandShadowOffsetY),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: height, minWidth: 44),
            child: Padding(
              padding: padding,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 8)],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.textTheme.displayMedium!.copyWith(
                        fontSize: fontSize,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      label: label,
      child: _PressScale(enabled: !disabled, child: button),
    );
  }
}

enum PrimaryButtonSize { small, medium, large }

class _PressScale extends StatefulWidget {
  const _PressScale({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    void update(bool pressed) {
      if (widget.enabled && pressed != _pressed) {
        setState(() => _pressed = pressed);
      }
    }

    return Listener(
      onPointerDown: (_) => update(true),
      onPointerUp: (_) => update(false),
      onPointerCancel: (_) => update(false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
