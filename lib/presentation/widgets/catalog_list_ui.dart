import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_icons.dart';
import '../../core/theme/app_typography.dart';
import 'app_icon.dart';
import 'motion/motion.dart';

enum CatalogWordAccent { search, favorite, mistake }

/// Shared list-row chrome for Ara / Favoriler / Yanlışlarım.
class CatalogWordTile extends StatelessWidget {
  const CatalogWordTile({
    super.key,
    required this.correct,
    required this.wrong,
    required this.onTap,
    this.accent = CatalogWordAccent.search,
    this.leading,
    this.trailing,
  });

  final String correct;
  final String wrong;
  final VoidCallback onTap;
  final CatalogWordAccent accent;
  final Widget? leading;
  final Widget? trailing;

  Color get _barColor => switch (accent) {
        CatalogWordAccent.search => AppColors.correct,
        CatalogWordAccent.favorite => AppColors.accent,
        CatalogWordAccent.mistake => AppColors.wrong,
      };

  @override
  Widget build(BuildContext context) {
    return AnimatedPressable(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.9)),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
              spreadRadius: -6,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Container(
                  width: 4,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _barColor,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(8),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    splashColor: _barColor.withValues(alpha: 0.08),
                    highlightColor: _barColor.withValues(alpha: 0.04),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                      child: Row(
                        children: [
                          if (leading != null) ...[
                            leading!,
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  correct,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.body(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                _WrongChip(wrong: wrong),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (trailing != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: trailing,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WrongChip extends StatelessWidget {
  const _WrongChip({required this.wrong});

  final String wrong;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.wrongSoft,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Yanlış  ',
                style: AppTypography.title(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.wrong,
                ),
              ),
              TextSpan(
                text: wrong,
                style: AppTypography.title(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.wrong.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class CatalogSearchField extends StatefulWidget {
  const CatalogSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.hintText,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  final bool autofocus;

  @override
  State<CatalogSearchField> createState() => _CatalogSearchFieldState();
}

class _CatalogSearchFieldState extends State<CatalogSearchField> {
  final _focus = FocusNode();
  var _focused = false;
  var _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.isNotEmpty;
    _focus.addListener(_onFocus);
    widget.controller.addListener(_onText);
  }

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocus)
      ..dispose();
    widget.controller.removeListener(_onText);
    super.dispose();
  }

  void _onFocus() {
    if (!mounted) return;
    setState(() => _focused = _focus.hasFocus);
  }

  void _onText() {
    final next = widget.controller.text.isNotEmpty;
    if (next == _hasText || !mounted) return;
    setState(() => _hasText = next);
  }

  void _clear() {
    widget.controller.clear();
    widget.onChanged('');
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppConstants.cardSwap,
      curve: AppConstants.pageCurve,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _focused ? AppColors.accent : const Color(0xFFE6E8EC),
          width: _focused ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _focused
                ? AppColors.accent.withValues(alpha: 0.18)
                : AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: _focused ? 18 : 12,
            offset: const Offset(0, 6),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: _SearchGlyph(),
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              autofocus: widget.autofocus,
              onChanged: widget.onChanged,
              textInputAction: TextInputAction.search,
              style: AppTypography.body(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              cursorColor: AppColors.accent,
              decoration: InputDecoration(
                isDense: true,
                hintText: widget.hintText,
                hintStyle: AppTypography.title(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary.withValues(alpha: 0.55),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.fromLTRB(10, 16, 8, 16),
              ),
            ),
          ),
          if (_hasText)
            IconButton(
              onPressed: _clear,
              tooltip: 'Temizle',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.close_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
            )
          else
            const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _SearchGlyph extends StatelessWidget {
  const _SearchGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.secondary, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.28),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const AppIcon(AppIcons.search, size: 18, color: Colors.white),
    );
  }
}

class CatalogEmptyState extends StatelessWidget {
  const CatalogEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.iconTint,
  });

  final String icon;
  final String title;
  final String message;
  final Color? iconTint;

  @override
  Widget build(BuildContext context) {
    final tint = iconTint ?? AppColors.accent;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: AppIcon(icon, size: 40),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.brand(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.title(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CatalogCircleButton extends StatelessWidget {
  const CatalogCircleButton({
    super.key,
    required this.onTap,
    required this.child,
    this.tooltip,
    this.highlighted = false,
  });

  final VoidCallback onTap;
  final Widget child;
  final String? tooltip;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final button = AnimatedPressable(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: highlighted
              ? AppColors.modeStreak
              : const Color(0xFFF4F5F7),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class CatalogCountChip extends StatelessWidget {
  const CatalogCountChip({
    super.key,
    required this.label,
    this.color = AppColors.accent,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.title(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
