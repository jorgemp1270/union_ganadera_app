import 'package:flutter/material.dart';

/// A Material 3 branded AppBar used throughout the app.
/// When [backgroundColor] is provided it overrides the theme's primary color,
/// which keeps per-screen accent tints (e.g. blue for vet screens).
class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color? backgroundColor;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  const ModernAppBar({
    super.key,
    required this.title,
    this.backgroundColor,
    this.leading,
    this.actions,
    this.bottom,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bgColor = backgroundColor ?? cs.primary;

    // Derive a legible foreground from the given background
    final fgColor =
        ThemeData.estimateBrightnessForColor(bgColor) == Brightness.dark
            ? Colors.white
            : cs.onSurface;

    return AppBar(
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: 0,
      scrolledUnderElevation: 2,
      shadowColor: Colors.black26,
      centerTitle: true,
      leading: leading,
      actions: actions,
      bottom: bottom,
      titleTextStyle: TextStyle(
        color: fgColor,
        fontSize: 19,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
      title: Text(title),
    );
  }
}
