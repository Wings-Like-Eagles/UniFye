import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_colour.dart';

enum AppButtonType {
  primary,
  secondary,
  outline,
  text,
  gradient,
}

enum AppButtonSize {
  small,
  medium,
  large,
}

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final AppButtonSize size;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final bool iconRight;
  final double? customWidth;
  final double? customHeight;

  const AppButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
    this.iconRight = false,
    this.customWidth,
    this.customHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonHeight = customHeight ?? _getHeight();
    final buttonWidth = isFullWidth
        ? double.infinity
        : (customWidth ?? (size == AppButtonSize.small ? 120.0 : null));

    return SizedBox(
      height: buttonHeight,
      width: buttonWidth,
      child: type == AppButtonType.gradient
          ? _buildGradientButton(context)
          : _buildStandardButton(context),
    );
  }

  Widget _buildStandardButton(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: _getButtonStyle(context),
      child: _buildButtonContent(context),
    );
  }

  Widget _buildGradientButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(_getBorderRadius()),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_getBorderRadius()),
          ),
          padding: _getPadding(),
        ),
        child: _buildButtonContent(context),
      ),
    );
  }

  ButtonStyle _getButtonStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (type) {
      case AppButtonType.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
          disabledForegroundColor: AppColors.textOnPrimary.withOpacity(0.5),
          elevation: 2,
          shadowColor: AppColors.shadowLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_getBorderRadius()),
          ),
          padding: _getPadding(),
        ).copyWith(
          overlayColor: MaterialStateProperty.all(
            Colors.white.withOpacity(0.1),
          ),
        );

      case AppButtonType.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.secondary.withOpacity(0.5),
          disabledForegroundColor: AppColors.primary.withOpacity(0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_getBorderRadius()),
          ),
          padding: _getPadding(),
        );

      case AppButtonType.outline:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.primary,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: AppColors.primary.withOpacity(0.5),
          elevation: 0,
          side: BorderSide(
            color: onPressed != null
                ? AppColors.primary
                : AppColors.primary.withOpacity(0.5),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_getBorderRadius()),
          ),
          padding: _getPadding(),
        );

      case AppButtonType.text:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.primary,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: AppColors.primary.withOpacity(0.5),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_getBorderRadius()),
          ),
          padding: _getPadding(),
        );

      default:
        return ElevatedButton.styleFrom();
    }
  }

  Widget _buildButtonContent(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: _getIconSize(),
        width: _getIconSize(),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            type == AppButtonType.primary || type == AppButtonType.gradient
                ? AppColors.textOnPrimary
                : AppColors.primary,
          ),
        ),
      );
    }

    if (icon == null) {
      return Text(
        text,
        style: _getTextStyle(context),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!iconRight) ...[
          Icon(icon, size: _getIconSize()),
          SizedBox(width: _getIconSpacing()),
        ],
        Text(
          text,
          style: _getTextStyle(context),
        ),
        if (iconRight) ...[
          SizedBox(width: _getIconSpacing()),
          Icon(icon, size: _getIconSize()),
        ],
      ],
    );
  }

  TextStyle _getTextStyle(BuildContext context) {
    final baseFontSize = _getFontSize();
    final fontWeight = type == AppButtonType.text
        ? FontWeight.w600
        : FontWeight.w700;

    return TextStyle(
      fontSize: baseFontSize,
      fontWeight: fontWeight,
      letterSpacing: 0.5,
    );
  }

  double _getHeight() {
    switch (size) {
      case AppButtonSize.small:
        return 36.0;
      case AppButtonSize.medium:
        return 48.0;
      case AppButtonSize.large:
        return 56.0;
    }
  }

  double _getFontSize() {
    switch (size) {
      case AppButtonSize.small:
        return 14.0;
      case AppButtonSize.medium:
        return 16.0;
      case AppButtonSize.large:
        return 18.0;
    }
  }

  double _getIconSize() {
    switch (size) {
      case AppButtonSize.small:
        return 18.0;
      case AppButtonSize.medium:
        return 20.0;
      case AppButtonSize.large:
        return 24.0;
    }
  }

  double _getIconSpacing() {
    switch (size) {
      case AppButtonSize.small:
        return 6.0;
      case AppButtonSize.medium:
        return 8.0;
      case AppButtonSize.large:
        return 10.0;
    }
  }

  double _getBorderRadius() {
    switch (size) {
      case AppButtonSize.small:
        return 20.0;
      case AppButtonSize.medium:
        return 24.0;
      case AppButtonSize.large:
        return 28.0;
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 32.0, vertical: 14.0);
    }
  }
}
