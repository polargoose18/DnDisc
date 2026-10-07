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
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Atmospheric Backdrop Image with smooth bottom gradient fade
            if (activeScene.imagePath != null &&
                activeScene.imagePath!.isNotEmpty &&
                File(activeScene.imagePath!).existsSync())
              Positioned.fill(
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black,
                        Colors.black87,
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.45, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: Image.file(
                    File(activeScene.imagePath!),
                    fit: BoxFit.cover,
                    color: Colors.black.withValues(alpha: 0.55),
                    colorBlendMode: BlendMode.darken,
                  ),
                ),
              )
            else
              Positioned.fill(
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black,
                        Colors.transparent,
                      ],
                      stops: [0.3, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          sceneColor.withValues(alpha: 0.35),
                          activeTheme.card.withValues(alpha: 0.95),
                          activeTheme.surface,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Content Layout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Centered Scene Title
                  Center(
                    child: Text(
                      activeScene.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: activeTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                        letterSpacing: 0.5,
                        fontFamilyFallback: const ['Georgia', 'Times New Roman', 'serif'],
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.75),
                            blurRadius: 8,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (activeScene.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        activeScene.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: activeTheme.textSecondary,
                          fontSize: 13,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),

                  // Integrated Intensity Level Pill Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: activeTheme.surface.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.tune_rounded, size: 14, color: activeTheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              '${l10n?.intensityLevel ?? 'Intensity Level'}:',
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
                            // Calm Pill
                            _buildModePill(
                              context: context,
                              title: l10n?.intensityCalm ?? 'Calm',
                              subtitle: null,
                              isSelected: musicBus.isPlaying && musicBus.currentIntensity == MusicIntensity.calm,
                              selectedColor: activeTheme.secondary,
                              activeTheme: activeTheme,
                              onTap: () {
                                musicBus.setIntensity(MusicIntensity.calm);
                                if (!musicBus.isPlaying) musicBus.resume();
                              },
                            ),
                            // Suspense Pill
                            _buildModePill(
                              context: context,
                              title: l10n?.intensitySuspense ?? 'Suspense',
                              subtitle: null,
                              isSelected: musicBus.isPlaying && musicBus.currentIntensity == MusicIntensity.suspense,
                              selectedColor: const Color(0xFFF59E0B),
                              activeTheme: activeTheme,
                              onTap: () {
                                musicBus.setIntensity(MusicIntensity.suspense);
                                if (!musicBus.isPlaying) musicBus.resume();
                              },
                            ),
                            // Battle Pill
                            _buildModePill(
                              context: context,
                              title: l10n?.intensityBattle ?? 'Battle',
                              subtitle: null,
                              isSelected: musicBus.isPlaying && musicBus.currentIntensity == MusicIntensity.battle,
                              selectedColor: activeTheme.battleIntensity,
                              activeTheme: activeTheme,
                              onTap: () {
                                musicBus.setIntensity(MusicIntensity.battle);
                                if (!musicBus.isPlaying) musicBus.resume();
                              },
                            ),
                            // Boss Pill
                            _buildModePill(
                              context: context,
                              title: l10n?.intensityBoss ?? 'Boss',
                              subtitle: null,
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
