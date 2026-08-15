import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_characters.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_icons.dart';
import '../../core/theme/app_typography.dart';
import '../../features/profile/profile_provider.dart';
import '../navigation/app_navigation.dart';
import '../navigation/soft_transitions.dart';
import '../providers/catalog_providers.dart';
import '../providers/stats_provider.dart';
import '../widgets/app_icon.dart';
import '../widgets/character_arc_carousel.dart';
import '../widgets/kelimatik_wordmark.dart';
import '../widgets/playful_background.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _usernameController = TextEditingController();
  String? _usernameError;
  bool _savingUsername = false;
  bool _editingUsername = false;
  bool _hydratedUsername = false;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _saveUsername() async {
    if (_savingUsername) return;
    final username = _usernameController.text;
    final validation = UsernameRules.validate(username);
    if (validation != null) {
      setState(() => _usernameError = validation);
      return;
    }

    final current = ref.read(currentProfileProvider).profile?.username;
    if (username == current) {
      setState(() {
        _editingUsername = false;
        _usernameError = null;
      });
      return;
    }

    setState(() {
      _savingUsername = true;
      _usernameError = null;
    });

    final error = await ref
        .read(currentProfileProvider.notifier)
        .updateIdentity(username: username);

    if (!mounted) return;

    setState(() {
      _savingUsername = false;
      if (error != null) {
        _usernameError = error;
      } else {
        _editingUsername = false;
        _usernameError = null;
      }
    });

    if (error == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı adı güncellendi')),
      );
    }
  }

  Future<void> _pickCharacter(String currentId) async {
    var selectedIndex = AppCharacters.ids.indexOf(currentId);
    if (selectedIndex < 0) selectedIndex = 0;

    final chosen = await showSoftModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _CharacterPickerSheet(
          initialIndex: selectedIndex,
          onConfirm: (id) => Navigator.of(sheetContext).pop(id),
        );
      },
    );

    if (chosen == null || !mounted) return;
    if (chosen == currentId) return;

    final error = await ref
        .read(currentProfileProvider.notifier)
        .updateIdentity(selectedCharacter: chosen);

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Karakter güncellendi')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(currentProfileProvider);
    final profile = profileState.profile;
    final stats = ref.watch(statsProvider);
    final bestStreak = ref.watch(bestStreakProvider);
    final dailyStreak = ref.watch(dailyStreakProvider);

    ref.listen(currentProfileProvider, (previous, next) {
      final name = next.profile?.username;
      if (name == null || _editingUsername) return;
      if (_usernameController.text != name) {
        _usernameController.text = name;
      }
    });

    if (!_hydratedUsername && profile != null) {
      _usernameController.text = profile.username;
      _hydratedUsername = true;
    }

    final characterId = profile?.selectedCharacter;
    final hasCharacter =
        characterId != null && AppCharacters.isValidId(characterId);
    final characterAsset = hasCharacter
        ? AppCharacters.assetFor(characterId)
        : AppCharacters.assetFor(AppCharacters.placeholderId);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PlayfulBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => AppNavigation.popRoute(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Text('Profil', style: AppTypography.brand(fontSize: 24)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: profile == null
                            ? null
                            : () => _pickCharacter(
                                  hasCharacter
                                      ? characterId
                                      : AppCharacters.ids.first,
                                ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 132,
                              height: 132,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.textPrimary
                                        .withValues(alpha: 0.07),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                    spreadRadius: -6,
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                characterAsset,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    const AppIcon(AppIcons.profile, size: 64),
                              ),
                            ),
                            Positioned(
                              right: -4,
                              bottom: -4,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Karakteri değiştirmek için dokun',
                      textAlign: TextAlign.center,
                      style: AppTypography.title(fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    if (_editingUsername) ...[
                      TextField(
                        controller: _usernameController,
                        enabled: !_savingUsername,
                        autocorrect: false,
                        enableSuggestions: false,
                        keyboardType: TextInputType.visiblePassword,
                        textInputAction: TextInputAction.done,
                        onChanged: (v) {
                          setState(() {
                            _usernameError = UsernameRules.validate(v);
                          });
                        },
                        onSubmitted: (_) => _saveUsername(),
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
                          labelText: 'Kullanıcı adı',
                          filled: true,
                          fillColor: AppColors.surfaceElevated,
                          errorText: _usernameError,
                          errorMaxLines: 2,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _savingUsername
                                  ? null
                                  : () {
                                      setState(() {
                                        _editingUsername = false;
                                        _usernameError = null;
                                        _usernameController.text =
                                            profile?.username ?? '';
                                      });
                                    },
                              child: const Text('Vazgeç'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: _savingUsername ||
                                      UsernameRules.validate(
                                            _usernameController.text,
                                          ) !=
                                          null
                                  ? null
                                  : _saveUsername,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                              ),
                              child: _savingUsername
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Kaydet'),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              profile?.username ?? '…',
                              textAlign: TextAlign.center,
                              style: AppTypography.brand(fontSize: 26),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Kullanıcı adını düzenle',
                            onPressed: profile == null
                                ? null
                                : () {
                                    setState(() {
                                      _editingUsername = true;
                                      _usernameError = null;
                                      _usernameController.text =
                                          profile.username;
                                    });
                                  },
                            icon: const Icon(
                              Icons.edit_rounded,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      profile == null
                          ? 'Profil yükleniyor…'
                          : 'Seviye ${profile.level}  ·  ${profile.xp} XP',
                      textAlign: TextAlign.center,
                      style: AppTypography.title(fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    _StatGrid(
                      items: [
                        _StatItem(
                          label: 'Doğru',
                          value: '${stats.totalCorrect}',
                          icon: AppIcons.correct,
                        ),
                        _StatItem(
                          label: 'Yanlış',
                          value: '${stats.totalWrong}',
                          icon: AppIcons.wrong,
                        ),
                        _StatItem(
                          label: 'Başarı',
                          value: '%${stats.successRate.round()}',
                          icon: AppIcons.info,
                        ),
                        _StatItem(
                          label: 'Günlük seri',
                          value: '${dailyStreak.current}',
                          icon: dailyStreak.isAlive && dailyStreak.current > 0
                              ? AppIcons.streakActive
                              : AppIcons.streakLost,
                        ),
                        _StatItem(
                          label: 'En iyi seri',
                          value: '$bestStreak',
                          icon: AppIcons.streakMode,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const Center(child: KelimatikWordmark(fontSize: 18)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CharacterPickerSheet extends StatefulWidget {
  const _CharacterPickerSheet({
    required this.initialIndex,
    required this.onConfirm,
  });

  final int initialIndex;
  final ValueChanged<String> onConfirm;

  @override
  State<_CharacterPickerSheet> createState() => _CharacterPickerSheetState();
}

class _CharacterPickerSheetState extends State<_CharacterPickerSheet> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, AppCharacters.ids.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
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
              const SizedBox(height: 16),
              Text(
                'Karakterini Seç',
                textAlign: TextAlign.center,
                style: AppTypography.brand(fontSize: 22),
              ),
              const SizedBox(height: 8),
              CharacterArcCarousel(
                characterIds: AppCharacters.ids,
                selectedIndex: _index,
                height: 240,
                onSelected: (i) => setState(() => _index = i),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () =>
                      widget.onConfirm(AppCharacters.ids[_index]),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Kaydet',
                    style: AppTypography.body(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final String icon;
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.items});

  final List<_StatItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        for (final item in items)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppIcon(item.icon, size: 22),
                const Spacer(),
                Text(
                  item.value,
                  style: AppTypography.brand(fontSize: 22),
                ),
                Text(
                  item.label,
                  style: AppTypography.title(fontSize: 12),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
