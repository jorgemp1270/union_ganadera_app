import 'package:flutter/material.dart';

/// A Material 3 Expressive AppBar.
///
/// Design language:
/// • Asymmetric layout — title left-aligned with a bold accent bar
/// • Back navigation is a compact rounded chip in [primaryContainer]
/// • A thin coloured vertical bar anchors the title to the leading edge
/// • Actions float to the far right, unstyled, letting each screen decide
/// • [backgroundColor] tints the accent bar and back chip; defaults to [ColorScheme.primary]
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
      Size.fromHeight(62 + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accentColor = backgroundColor ?? cs.primary;

    final accentFg =
        ThemeData.estimateBrightnessForColor(accentColor) == Brightness.dark
            ? Colors.white
            : cs.onPrimary;

    final canPop = Navigator.of(context).canPop();

    // Compact back chip: rounded pill in primaryContainer
    final backChip =
        canPop
            ? Padding(
              padding: const EdgeInsets.fromLTRB(12, 11, 0, 11),
              child: Material(
                color: accentColor,
                borderRadius: BorderRadius.circular(22),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => Navigator.of(context).pop(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: accentFg,
                      size: 20,
                    ),
                  ),
                ),
              ),
            )
            : null;

    return AppBar(
      backgroundColor: cs.surfaceContainerLowest,
      foregroundColor: cs.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: cs.shadow.withValues(alpha: 0.08),
      automaticallyImplyLeading: false,
      toolbarHeight: 62,
      titleSpacing: 0,
      bottom: bottom,
      // Back chip as leading, or nothing (title then handles its own left padding)
      leading: leading ?? backChip,
      leadingWidth: (leading != null || canPop) ? 68 : 0,
      title: Row(
        children: [
          // Accent bar — the asymmetric eye-catcher
          Container(
            width: 5,
            height: 34,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 21,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions:
          actions != null
              ? [...actions!, const SizedBox(width: 8)]
              : [const SizedBox(width: 4)],
    );
  }
}
