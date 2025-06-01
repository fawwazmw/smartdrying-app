import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? splashColor;
  final Color? disabledBackgroundColor;
  final Color? disabledTextColor;
  final double? elevation;
  final BorderSide? borderSide;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final bool isLoading;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final double? iconSpacing;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.splashColor, // Dapat digunakan untuk kustomisasi lebih lanjut pada ElevatedButton.styleFrom
    this.disabledBackgroundColor,
    this.disabledTextColor,
    this.elevation,
    this.borderSide,
    this.padding,
    this.borderRadius = 12.0,
    this.isLoading = false,
    this.leadingIcon,
    this.trailingIcon,
    this.iconSpacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // Menentukan warna efektif berdasarkan input atau tema default
    final Color effectiveBackgroundColor = backgroundColor ?? theme.colorScheme.primary;
    final Color effectiveTextColor = textColor ?? theme.colorScheme.onPrimary;
    final Color effectiveDisabledBackgroundColor = disabledBackgroundColor ?? theme.colorScheme.onSurface.withOpacity(0.12);
    final Color effectiveDisabledTextColor = disabledTextColor ?? theme.colorScheme.onSurface.withOpacity(0.38);

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isLoading ? effectiveDisabledBackgroundColor : effectiveBackgroundColor,
        foregroundColor: isLoading ? effectiveDisabledTextColor : effectiveTextColor,
        disabledBackgroundColor: effectiveDisabledBackgroundColor,
        disabledForegroundColor: effectiveDisabledTextColor,
        elevation: isLoading ? 0 : elevation,
        minimumSize: const Size(double.infinity, 50),
        padding: padding ?? const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: borderSide ?? BorderSide.none,
        ),
        splashFactory: isLoading ? NoSplash.splashFactory : InkRipple.splashFactory,
        // Anda bisa menambahkan properti splashColor di sini jika diinginkan:
        // overlayColor: MaterialStateProperty.resolveWith<Color?>(
        //   (Set<MaterialState> states) {
        //     if (states.contains(MaterialState.pressed) && splashColor != null) {
        //       return splashColor;
        //     }
        //     return null; // Menggunakan default dari foregroundColor
        //   },
        // ),
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(effectiveTextColor),
        ),
      )
          : Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (leadingIcon != null) ...[
            leadingIcon!,
            SizedBox(width: iconSpacing),
          ],
          Text(
            text,
            style: TextStyle(
              // Warna teks utama diatur oleh foregroundColor pada ElevatedButton.styleFrom.
              // Jika ingin override spesifik di sini, gunakan:
              // color: isLoading ? effectiveDisabledTextColor : effectiveTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (trailingIcon != null) ...[
            SizedBox(width: iconSpacing),
            trailingIcon!,
          ],
        ],
      ),
    );
  }
}