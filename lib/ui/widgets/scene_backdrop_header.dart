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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: activeTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: activeTheme.textSecondary.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(Icons.theater_comedy_rounded, color: activeTheme.textSecondary, size: 28),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: sceneColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: sceneColor.withValues(alpha: 0.25),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // Background Image or atmospheric backdrop gradient
            if (activeScene.imagePath != null &&
                activeScene.imagePath!.isNotEmpty &&
                File(activeScene.imagePath!).existsSync())
              Positioned.fill(
                child: Image.file(
                  File(activeScene.imagePath!),
                  fit: BoxFit.cover,
                  color: Colors.black.withValues(alpha: 0.7),
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
                        sceneColor.withValues(alpha: 0.55),
                        activeTheme.surface.withValues(alpha: 0.95),
                      ],
                    ),
                  ),
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: sceneColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: sceneColor.withValues(alpha: 0.6), blurRadius: 10),
                      ],
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
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
                                fontSize: 18,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: activeTheme.primary.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: activeTheme.primary, width: 0.8),
                              ),
                              child: Text(
                                l10n?.currentSceneBadge ?? 'CURRENT SCENE',
                                style: TextStyle(
                                  color: activeTheme.textPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (activeScene.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
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
                  const SizedBox(width: 12),
                  // Quick Music Intensity Selector
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n?.musicIntensityLabel ?? 'Music Intensity',
                        style: TextStyle(color: activeTheme.textSecondary, fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildIntensityBtn(context, MusicIntensity.calm.getLocalizedName(l10n), MusicIntensity.calm, musicBus, activeTheme),
                          const SizedBox(width: 4),
                          _buildIntensityBtn(context, MusicIntensity.suspense.getLocalizedName(l10n), MusicIntensity.suspense, musicBus, activeTheme),
                          const SizedBox(width: 4),
                          _buildIntensityBtn(context, MusicIntensity.battle.getLocalizedName(l10n), MusicIntensity.battle, musicBus, activeTheme),
                          const SizedBox(width: 4),
                          _buildIntensityBtn(context, MusicIntensity.boss.getLocalizedName(l10n), MusicIntensity.boss, musicBus, activeTheme),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntensityBtn(
    BuildContext context,
    String label,
    MusicIntensity intensity,
    MusicBusController musicBus,
    dynamic activeTheme,
  ) {
    final isSelected = musicBus.currentIntensity == intensity;
    Color color;
    switch (intensity) {
      case MusicIntensity.calm:
        color = activeTheme.secondary;
        break;
      case MusicIntensity.suspense:
        color = Colors.amberAccent;
        break;
      case MusicIntensity.battle:
        color = activeTheme.battleIntensity;
        break;
      case MusicIntensity.boss:
        color = activeTheme.bossIntensity;
        break;
    }

    return InkWell(
      onTap: () => musicBus.setIntensity(intensity),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color, width: isSelected ? 1.5 : 0.8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
