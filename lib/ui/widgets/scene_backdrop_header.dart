import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/view_models/scene_view_model.dart';
import '../../ui/view_models/theme_view_model.dart';
import '../../audio/music_bus_controller.dart';
import '../../domain/models/audio_track.dart';

import '../../theme/app_themes.dart';

class SceneBackdropHeader extends StatelessWidget {
  const SceneBackdropHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final sceneViewModel = context.watch<SceneViewModel>();
    final themeViewModel = context.watch<ThemeViewModel?>();
    final musicBus = context.watch<MusicBusController>();
    final activeTheme = themeViewModel?.activeTheme ?? AppThemes.deepDark;
    final activeScene = sceneViewModel.activeScene;
    final l10n = AppLocalizations.of(context);

    if (activeScene == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: activeTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Icon(Icons.theater_comedy_rounded, color: activeTheme.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n?.selectScenePrompt ?? 'Select a scene on the left to set up the game environment',
                style: TextStyle(color: activeTheme.textSecondary, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    final sceneColor = Color(activeScene.colorHex);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: activeTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: activeTheme.primary.withValues(alpha: 0.25), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // Atmospheric Backdrop Image or Warm Vignette Gradient
            if (activeScene.imagePath != null &&
                activeScene.imagePath!.isNotEmpty &&
                File(activeScene.imagePath!).existsSync())
              Positioned.fill(
                child: Image.file(
                  File(activeScene.imagePath!),
                  fit: BoxFit.cover,
                  color: Colors.black.withValues(alpha: 0.72),
                  colorBlendMode: BlendMode.darken,
                ),
              )
            else
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        sceneColor.withValues(alpha: 0.28),
                        activeTheme.card.withValues(alpha: 0.95),
                        activeTheme.surface,
                      ],
                    ),
                  ),
                ),
              ),

            // Content Layout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: sceneColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: sceneColor.withValues(alpha: 0.6), width: 1.2),
                        ),
                        child: Icon(Icons.auto_awesome, color: activeTheme.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Text(
                                  activeScene.name,
                                  style: TextStyle(
                                    color: activeTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    letterSpacing: 0.4,
                                    fontFamilyFallback: const ['Georgia', 'Times New Roman', 'serif'],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: activeTheme.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: activeTheme.primary.withValues(alpha: 0.5), width: 0.8),
                                  ),
                                  child: Text(
                                    l10n?.currentSceneBadge ?? 'CURRENT SCENE',
                                    style: TextStyle(
                                      color: activeTheme.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (activeScene.description.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                activeScene.description,
                                style: TextStyle(color: activeTheme.textSecondary, fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Integrated Active Music Mode Pill Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: activeTheme.surface.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.tune_rounded, size: 14, color: activeTheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              l10n?.activeMusicMode ?? 'Active music mode:',
                              style: TextStyle(
                                color: activeTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            // Off Pill
                            _buildModePill(
                              context: context,
                              title: l10n?.musicModeOff ?? 'Off',
                              subtitle: null,
                              isSelected: !musicBus.isPlaying,
                              selectedColor: Colors.grey.shade400,
                              activeTheme: activeTheme,
                              onTap: () {
                                if (musicBus.isPlaying) {
                                  musicBus.pause();
                                }
                              },
                            ),
                            // Explore (Calm) Pill
                            _buildModePill(
                              context: context,
                              title: l10n?.musicModeExplore ?? 'Explore',
                              subtitle: l10n?.intensityCalm ?? 'Calm',
                              isSelected: musicBus.isPlaying && musicBus.currentIntensity == MusicIntensity.calm,
                              selectedColor: activeTheme.secondary,
                              activeTheme: activeTheme,
                              onTap: () {
                                musicBus.setIntensity(MusicIntensity.calm);
                                if (!musicBus.isPlaying) musicBus.resume();
                              },
                            ),
                            // Combat (Battle) Pill
                            _buildModePill(
                              context: context,
                              title: l10n?.musicModeCombat ?? 'Combat',
                              subtitle: l10n?.intensityBattle ?? 'Battle',
                              isSelected: musicBus.isPlaying &&
                                  (musicBus.currentIntensity == MusicIntensity.battle ||
                                      musicBus.currentIntensity == MusicIntensity.suspense),
                              selectedColor: activeTheme.battleIntensity,
                              activeTheme: activeTheme,
                              onTap: () {
                                musicBus.setIntensity(MusicIntensity.battle);
                                if (!musicBus.isPlaying) musicBus.resume();
                              },
                            ),
                            // Victory (Boss) Pill
                            _buildModePill(
                              context: context,
                              title: l10n?.musicModeVictory ?? 'Victory',
                              subtitle: l10n?.intensityBoss ?? 'Boss',
                              isSelected: musicBus.isPlaying && musicBus.currentIntensity == MusicIntensity.boss,
                              selectedColor: activeTheme.bossIntensity,
                              activeTheme: activeTheme,
                              onTap: () {
                                musicBus.setIntensity(MusicIntensity.boss);
                                if (!musicBus.isPlaying) musicBus.resume();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModePill({
    required BuildContext context,
    required String title,
    required String? subtitle,
    required bool isSelected,
    required Color selectedColor,
    required dynamic activeTheme,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor.withValues(alpha: 0.28) : activeTheme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? selectedColor : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 1.4 : 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : activeTheme.textPrimary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(width: 4),
              Text(
                '·',
                style: TextStyle(
                  color: isSelected ? Colors.white60 : activeTheme.textSecondary.withValues(alpha: 0.5),
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: isSelected ? Colors.white70 : activeTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
