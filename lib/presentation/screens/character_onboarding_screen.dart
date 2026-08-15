import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_characters.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_typography.dart';
import '../../features/profile/profile_provider.dart';
import '../widgets/character_arc_carousel.dart';
import '../widgets/kelimatik_wordmark.dart';
import '../widgets/playful_background.dart';

/// First-time Google users: pick character + username, then enter the app.
class CharacterOnboardingScreen extends ConsumerStatefulWidget {
  const CharacterOnboardingScreen({super.key});

  @override
  ConsumerState<CharacterOnboardingScreen> createState() =>
      _CharacterOnboardingScreenState();
}

class _CharacterOnboardingScreenState
    extends ConsumerState<CharacterOnboardingScreen> {
  final _usernameController = TextEditingController();
  final _usernameFocus = FocusNode();

  int _selectedIndex = AppCharacters.initialCarouselIndex;
  String? _usernameError;
  bool _submitting = false;

  String get _selectedCharacterId =>
      AppCharacters.carouselIds[_selectedIndex];

  bool get _hasRealCharacter =>
      AppCharacters.isValidId(_selectedCharacterId);

  @override
  void dispose() {
    _usernameController.dispose();
    _usernameFocus.dispose();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    setState(() {
      _usernameError = UsernameRules.validate(value);
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final username = _usernameController.text;
    final validationError = UsernameRules.validate(username);
    if (validationError != null) {
      setState(() => _usernameError = validationError);
      return;
    }
    if (!_hasRealCharacter) {
      setState(() => _usernameError = 'Lütfen bir karakter seç.');
      return;
    }

    setState(() {
      _submitting = true;
      _usernameError = null;
    });

    final error = await ref.read(currentProfileProvider.notifier).completeOnboarding(
          username: username,
          selectedCharacter: _selectedCharacterId,
        );

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _submitting = false;
        _usernameError = error;
      });
      return;
    }

    // AuthGate watches profile.onboardingCompleted and opens MainShell.
    setState(() => _submitting = false);
  }

  bool get _canSubmit {
    if (_submitting) return false;
    if (!_hasRealCharacter) return false;
    final username = _usernameController.text;
    return UsernameRules.validate(username) == null;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: PlayfulBackground(
        child: SafeArea(
          child: AnimatedPadding(
            duration: AppConstants.pressOutDuration,
            curve: AppConstants.pageCurve,
            padding: EdgeInsets.only(bottom: bottomInset > 0 ? 8 : 0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final carouselHeight =
                    (constraints.maxHeight * 0.42).clamp(220.0, 320.0);

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 40,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: KelimatikWordmark(fontSize: 28)),
                        const SizedBox(height: 20),
                        Text(
                          'Karakterini Seç',
                          textAlign: TextAlign.center,
                          style: AppTypography.brand(fontSize: 26),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Kelimatik’teki karakterini seç.',
                          textAlign: TextAlign.center,
                          style: AppTypography.title(fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        CharacterArcCarousel(
                          characterIds: AppCharacters.carouselIds,
                          selectedIndex: _selectedIndex,
                          height: carouselHeight,
                          onSelected: (index) {
                            setState(() {
                              _selectedIndex = index;
                              if (_usernameError == 'Lütfen bir karakter seç.' &&
                                  AppCharacters.isValidId(
                                    AppCharacters.carouselIds[index],
                                  )) {
                                _usernameError = null;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        _CharacterDots(
                          count: AppCharacters.carouselIds.length,
                          selectedIndex: _selectedIndex,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Kullanıcı adı',
                          style: AppTypography.title(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _usernameController,
                          focusNode: _usernameFocus,
                          enabled: !_submitting,
                          autocorrect: false,
                          enableSuggestions: false,
                          keyboardType: TextInputType.visiblePassword,
                          textInputAction: TextInputAction.done,
                          onChanged: _onUsernameChanged,
                          onSubmitted: (_) {
                            if (_canSubmit) _submit();
                          },
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(
                              UsernameRules.maxLength,
                            ),
                          ],
                          style: AppTypography.body(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Kullanıcı adı',
                            hintStyle: AppTypography.title(fontSize: 15),
                            filled: true,
                            fillColor: AppColors.surfaceElevated,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: AppColors.divider),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: AppColors.divider),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: AppColors.wrong),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppColors.wrong,
                                width: 1.5,
                              ),
                            ),
                            errorText: _usernameError,
                            errorMaxLines: 2,
                            errorStyle: AppTypography.title(
                              fontSize: 12,
                              color: AppColors.wrong,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sadece küçük İngilizce harf (a–z) ve rakam (0–9).',
                          style: AppTypography.title(fontSize: 12),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton(
                            onPressed: _canSubmit ? _submit : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              disabledBackgroundColor:
                                  AppColors.primary.withValues(alpha: 0.4),
                              foregroundColor: AppColors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Devam Et',
                                    style: AppTypography.body(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CharacterDots extends StatelessWidget {
  const _CharacterDots({
    required this.count,
    required this.selectedIndex,
  });

  final int count;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          AnimatedContainer(
            duration: AppConstants.pressOutDuration,
            curve: AppConstants.pageCurve,
            width: i == selectedIndex ? 8 : 6,
            height: i == selectedIndex ? 8 : 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == selectedIndex
                  ? AppColors.primary
                  : AppColors.textSecondary.withValues(alpha: 0.35),
            ),
          ),
        ],
      ],
    );
  }
}
