import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_typography.dart';
import '../../data/services/word_report_service.dart';
import '../../domain/models/word_pair.dart';
import '../../domain/models/word_report.dart';
import '../navigation/soft_transitions.dart';

Future<void> showWordReportSheet(BuildContext context, WordPair word) {
  return showSoftModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _WordReportSheet(word: word),
  );
}

class _WordReportSheet extends StatefulWidget {
  const _WordReportSheet({required this.word});

  final WordPair word;

  @override
  State<_WordReportSheet> createState() => _WordReportSheetState();
}

class _WordReportSheetState extends State<_WordReportSheet> {
  final _noteController = TextEditingController();
  final _noteFocus = FocusNode();
  final _service = WordReportService();

  WordReportReason? _reason;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _noteController.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_sending && WordReportDraft.canSubmit(_reason, _noteController.text);

  void _select(WordReportReason reason) {
    setState(() {
      _reason = reason;
      _error = null;
    });
    if (reason == WordReportReason.other) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _noteFocus.requestFocus();
      });
    }
  }

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null || !_canSubmit) return;

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      await _service.submit(
        word: widget.word,
        reason: reason,
        note: _noteController.text,
      );
    } on WordReportFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = failure.message;
      });
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = WordReportFailure.unavailable.message;
      });
      return;
    }

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('Bildirimin ulaştı, teşekkürler.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF7F8FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Sorun bildir', style: AppTypography.brand(fontSize: 24)),
                const SizedBox(height: 4),
                Text(
                  widget.word.correct,
                  style: AppTypography.body(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.wrongSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Yanlış: ${widget.word.wrong}',
                      style: AppTypography.title(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.wrong,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                for (final reason in WordReportReason.values) ...[
                  _ReasonTile(
                    reason: reason,
                    selected: _reason == reason,
                    onTap: _sending ? null : () => _select(reason),
                  ),
                  const SizedBox(height: 10),
                ],
                if (_reason == WordReportReason.other) ...[
                  TextField(
                    controller: _noteController,
                    focusNode: _noteFocus,
                    enabled: !_sending,
                    maxLength: WordReportDraft.maxNoteLength,
                    minLines: 2,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setState(() => _error = null),
                    style: AppTypography.body(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Sorunu kısaca yaz',
                      hintStyle: AppTypography.title(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      filled: true,
                      fillColor: AppColors.white,
                      counterStyle: AppTypography.title(fontSize: 11),
                      contentPadding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE6E8EC)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE6E8EC)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: AppTypography.title(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.wrong,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 6),
                FilledButton(
                  onPressed: _canSubmit ? _submit : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.35),
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : Text(
                          'Bildir',
                          style: AppTypography.body(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  final WordReportReason reason;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = reason.subtitle;

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: AppColors.accent.withValues(alpha: 0.10),
        highlightColor: AppColors.accent.withValues(alpha: 0.05),
        child: Ink(
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFF6EB) : AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.primary : const Color(0xFFE6E8EC),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reason.label,
                        style: AppTypography.body(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: AppTypography.title(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
