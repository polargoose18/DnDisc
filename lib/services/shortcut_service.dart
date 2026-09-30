import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../audio/audio_engine_service.dart';
import '../domain/models/audio_track.dart';
import '../l10n/app_localizations.dart';
import 'logger_service.dart';

enum AppShortcutAction {
  playPauseMusic,
  intensityCalm,
  intensitySuspense,
  intensityBattle,
  intensityBoss,
  sfx1,
  sfx2,
  sfx3,
  sfx4,
  sfx5,
  sfx6,
  sfx7,
  sfx8,
  sfx9,
  masterMute,
  manualDucking,
  panicStopSfx,
  toggleFullscreen,
}

class ShortcutDefinition {
  final AppShortcutAction action;
  final String title;
  final String description;
  final String keyDisplay;

  const ShortcutDefinition({
    required this.action,
    required this.title,
    required this.description,
    required this.keyDisplay,
  });
}

extension ShortcutDefinitionLocalizationExtension on ShortcutDefinition {
  String getLocalizedTitle([AppLocalizations? l10n]) {
    if (l10n == null) return title;
    switch (action) {
      case AppShortcutAction.playPauseMusic:
        return l10n.shortcutPlayPauseTitle;
      case AppShortcutAction.intensityCalm:
        return l10n.shortcutIntensityCalmTitle;
      case AppShortcutAction.intensitySuspense:
        return l10n.shortcutIntensitySuspenseTitle;
      case AppShortcutAction.intensityBattle:
        return l10n.shortcutIntensityBattleTitle;
      case AppShortcutAction.intensityBoss:
        return l10n.shortcutIntensityBossTitle;
      case AppShortcutAction.sfx1:
        return l10n.shortcutSfxTitle(1);
      case AppShortcutAction.sfx2:
        return l10n.shortcutSfxTitle(2);
      case AppShortcutAction.sfx3:
        return l10n.shortcutSfxTitle(3);
      case AppShortcutAction.sfx4:
        return l10n.shortcutSfxTitle(4);
      case AppShortcutAction.sfx5:
        return l10n.shortcutSfxTitle(5);
      case AppShortcutAction.sfx6:
        return l10n.shortcutSfxTitle(6);
      case AppShortcutAction.sfx7:
        return l10n.shortcutSfxTitle(7);
      case AppShortcutAction.sfx8:
        return l10n.shortcutSfxTitle(8);
      case AppShortcutAction.sfx9:
        return l10n.shortcutSfxTitle(9);
      case AppShortcutAction.masterMute:
        return l10n.shortcutMasterMuteTitle;
      case AppShortcutAction.manualDucking:
        return l10n.shortcutManualDuckingTitle;
      case AppShortcutAction.panicStopSfx:
        return l10n.shortcutPanicStopTitle;
      case AppShortcutAction.toggleFullscreen:
        return l10n.shortcutFullscreenTitle;
    }
  }

  String getLocalizedDescription([AppLocalizations? l10n]) {
    if (l10n == null) return description;
    switch (action) {
      case AppShortcutAction.playPauseMusic:
        return l10n.shortcutPlayPauseDesc;
      case AppShortcutAction.intensityCalm:
        return l10n.shortcutIntensityCalmDesc;
      case AppShortcutAction.intensitySuspense:
        return l10n.shortcutIntensitySuspenseDesc;
      case AppShortcutAction.intensityBattle:
        return l10n.shortcutIntensityBattleDesc;
      case AppShortcutAction.intensityBoss:
        return l10n.shortcutIntensityBossDesc;
      case AppShortcutAction.sfx1:
        return l10n.shortcutSfxDesc(1);
      case AppShortcutAction.sfx2:
        return l10n.shortcutSfxDesc(2);
      case AppShortcutAction.sfx3:
        return l10n.shortcutSfxDesc(3);
      case AppShortcutAction.sfx4:
        return l10n.shortcutSfxDesc(4);
      case AppShortcutAction.sfx5:
        return l10n.shortcutSfxDesc(5);
      case AppShortcutAction.sfx6:
        return l10n.shortcutSfxDesc(6);
      case AppShortcutAction.sfx7:
        return l10n.shortcutSfxDesc(7);
      case AppShortcutAction.sfx8:
        return l10n.shortcutSfxDesc(8);
      case AppShortcutAction.sfx9:
        return l10n.shortcutSfxDesc(9);
      case AppShortcutAction.masterMute:
        return l10n.shortcutMasterMuteDesc;
      case AppShortcutAction.manualDucking:
        return l10n.shortcutManualDuckingDesc;
      case AppShortcutAction.panicStopSfx:
        return l10n.shortcutPanicStopDesc;
      case AppShortcutAction.toggleFullscreen:
        return l10n.shortcutFullscreenDesc;
    }
  }
}

class ShortcutService extends ChangeNotifier {
  bool _isEnabled = true;
  AudioEngineService? _audioEngine;
  bool _isFullscreen = false;

  final Map<AppShortcutAction, ShortcutDefinition> _definitions = {
    AppShortcutAction.playPauseMusic: const ShortcutDefinition(
      action: AppShortcutAction.playPauseMusic,
      title: 'Play / Pause',
      description: 'Start or pause current music track',
      keyDisplay: 'Space',
    ),
    AppShortcutAction.intensityCalm: const ShortcutDefinition(
      action: AppShortcutAction.intensityCalm,
      title: 'Intensity: Calm',
      description: 'Switch music mode to Calm',
      keyDisplay: '1',
    ),
    AppShortcutAction.intensitySuspense: const ShortcutDefinition(
      action: AppShortcutAction.intensitySuspense,
      title: 'Intensity: Suspense',
      description: 'Switch music mode to Suspense',
      keyDisplay: '2',
    ),
    AppShortcutAction.intensityBattle: const ShortcutDefinition(
      action: AppShortcutAction.intensityBattle,
      title: 'Intensity: Battle',
      description: 'Switch music mode to Battle',
      keyDisplay: '3',
    ),
    AppShortcutAction.intensityBoss: const ShortcutDefinition(
      action: AppShortcutAction.intensityBoss,
      title: 'Intensity: Boss',
      description: 'Switch music mode to Boss',
      keyDisplay: '4',
    ),
    AppShortcutAction.sfx1: const ShortcutDefinition(
      action: AppShortcutAction.sfx1,
      title: 'SFX Slot 1',
      description: 'Trigger sound effect 1',
      keyDisplay: 'Num 1 / Ctrl+1',
    ),
    AppShortcutAction.sfx2: const ShortcutDefinition(
      action: AppShortcutAction.sfx2,
      title: 'SFX Slot 2',
      description: 'Trigger sound effect 2',
      keyDisplay: 'Num 2 / Ctrl+2',
    ),
    AppShortcutAction.sfx3: const ShortcutDefinition(
      action: AppShortcutAction.sfx3,
      title: 'SFX Slot 3',
      description: 'Trigger sound effect 3',
      keyDisplay: 'Num 3 / Ctrl+3',
    ),
    AppShortcutAction.sfx4: const ShortcutDefinition(
      action: AppShortcutAction.sfx4,
      title: 'SFX Slot 4',
      description: 'Trigger sound effect 4',
      keyDisplay: 'Num 4 / Ctrl+4',
    ),
    AppShortcutAction.sfx5: const ShortcutDefinition(
      action: AppShortcutAction.sfx5,
      title: 'SFX Slot 5',
      description: 'Trigger sound effect 5',
      keyDisplay: 'Num 5 / Ctrl+5',
    ),
    AppShortcutAction.sfx6: const ShortcutDefinition(
      action: AppShortcutAction.sfx6,
      title: 'SFX Slot 6',
      description: 'Trigger sound effect 6',
      keyDisplay: 'Num 6 / Ctrl+6',
    ),
    AppShortcutAction.sfx7: const ShortcutDefinition(
      action: AppShortcutAction.sfx7,
      title: 'SFX Slot 7',
      description: 'Trigger sound effect 7',
      keyDisplay: 'Num 7 / Ctrl+7',
    ),
    AppShortcutAction.sfx8: const ShortcutDefinition(
      action: AppShortcutAction.sfx8,
      title: 'SFX Slot 8',
      description: 'Trigger sound effect 8',
      keyDisplay: 'Num 8 / Ctrl+8',
    ),
    AppShortcutAction.sfx9: const ShortcutDefinition(
      action: AppShortcutAction.sfx9,
      title: 'SFX Slot 9',
      description: 'Trigger sound effect 9',
      keyDisplay: 'Num 9 / Ctrl+9',
    ),
    AppShortcutAction.masterMute: const ShortcutDefinition(
      action: AppShortcutAction.masterMute,
      title: 'Mute Audio',
      description: 'Quick mute or unmute master audio',
      keyDisplay: 'M',
    ),
    AppShortcutAction.manualDucking: const ShortcutDefinition(
      action: AppShortcutAction.manualDucking,
      title: 'Manual Ducking',
      description: 'Duck music during speech',
      keyDisplay: 'D',
    ),
    AppShortcutAction.panicStopSfx: const ShortcutDefinition(
      action: AppShortcutAction.panicStopSfx,
      title: 'Panic Stop SFX',
      description: 'Instantly stop all playing SFX sounds',
      keyDisplay: 'Escape',
    ),
    AppShortcutAction.toggleFullscreen: const ShortcutDefinition(
      action: AppShortcutAction.toggleFullscreen,
      title: 'Fullscreen Mode',
      description: 'Toggle fullscreen display',
      keyDisplay: 'F11',
    ),
  };

  ShortcutService({AudioEngineService? audioEngine}) : _audioEngine = audioEngine {
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  bool get isEnabled => _isEnabled;
  bool get isFullscreen => _isFullscreen;
  List<ShortcutDefinition> get allDefinitions => _definitions.values.toList();

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    notifyListeners();
  }

  void attachAudioEngine(AudioEngineService audioEngine) {
    _audioEngine = audioEngine;
  }

  String getDisplayForAction(AppShortcutAction action) {
    return _definitions[action]?.keyDisplay ?? '';
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (!_isEnabled || _audioEngine == null) return false;
    if (event is! KeyDownEvent) return false;

    // Check if user is typing in a text field
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus != null && primaryFocus.context != null) {
      final context = primaryFocus.context!;
      final isEditable = context.widget is EditableText ||
          context.findAncestorWidgetOfExactType<EditableText>() != null;
      if (isEditable) {
        // Allow escape even in editable text to lose focus or panic stop
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          primaryFocus.unfocus();
          return false;
        }
        return false;
      }
    }

    final isCtrl = HardwareKeyboard.instance.isControlPressed;

    // Space -> Play/Pause
    if (event.logicalKey == LogicalKeyboardKey.space) {
      _executeAction(AppShortcutAction.playPauseMusic);
      return true;
    }

    // Escape -> Panic Stop
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _executeAction(AppShortcutAction.panicStopSfx);
      return true;
    }

    // Key M -> Master Mute
    if (event.logicalKey == LogicalKeyboardKey.keyM) {
      _executeAction(AppShortcutAction.masterMute);
      return true;
    }

    // Key D -> Manual Ducking
    if (event.logicalKey == LogicalKeyboardKey.keyD) {
      _executeAction(AppShortcutAction.manualDucking);
      return true;
    }

    // F11 -> Fullscreen Toggle
    if (event.logicalKey == LogicalKeyboardKey.f11) {
      _executeAction(AppShortcutAction.toggleFullscreen);
      return true;
    }

    // Digit 1..4 (without Ctrl) -> Music Intensity
    if (!isCtrl) {
      if (event.logicalKey == LogicalKeyboardKey.digit1) {
        _executeAction(AppShortcutAction.intensityCalm);
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.digit2) {
        _executeAction(AppShortcutAction.intensitySuspense);
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.digit3) {
        _executeAction(AppShortcutAction.intensityBattle);
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.digit4) {
        _executeAction(AppShortcutAction.intensityBoss);
        return true;
      }
    }

    // Numpad 1..9 or Ctrl+1..9 -> SFX 1..9
    final numpadKeys = [
      LogicalKeyboardKey.numpad1,
      LogicalKeyboardKey.numpad2,
      LogicalKeyboardKey.numpad3,
      LogicalKeyboardKey.numpad4,
      LogicalKeyboardKey.numpad5,
      LogicalKeyboardKey.numpad6,
      LogicalKeyboardKey.numpad7,
      LogicalKeyboardKey.numpad8,
      LogicalKeyboardKey.numpad9,
    ];

    final digitKeys = [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6,
      LogicalKeyboardKey.digit7,
      LogicalKeyboardKey.digit8,
      LogicalKeyboardKey.digit9,
    ];

    for (int i = 0; i < 9; i++) {
      if (event.logicalKey == numpadKeys[i] || (isCtrl && event.logicalKey == digitKeys[i])) {
        final action = AppShortcutAction.values[AppShortcutAction.sfx1.index + i];
        _executeAction(action);
        return true;
      }
    }

    return false;
  }

  void _executeAction(AppShortcutAction action) {
    if (_audioEngine == null) return;
    LoggerService().info('ShortcutService: Executing action "$action"');

    switch (action) {
      case AppShortcutAction.playPauseMusic:
        if (_audioEngine!.musicBus.isPlaying) {
          _audioEngine!.musicBus.pause();
        } else {
          _audioEngine!.musicBus.resume();
        }
        break;

      case AppShortcutAction.intensityCalm:
        _audioEngine!.musicBus.setIntensity(MusicIntensity.calm);
        break;
      case AppShortcutAction.intensitySuspense:
        _audioEngine!.musicBus.setIntensity(MusicIntensity.suspense);
        break;
      case AppShortcutAction.intensityBattle:
        _audioEngine!.musicBus.setIntensity(MusicIntensity.battle);
        break;
      case AppShortcutAction.intensityBoss:
        _audioEngine!.musicBus.setIntensity(MusicIntensity.boss);
        break;

      case AppShortcutAction.masterMute:
        _audioEngine!.toggleMute();
        break;

      case AppShortcutAction.manualDucking:
        _audioEngine!.triggerManualDuck();
        break;

      case AppShortcutAction.panicStopSfx:
        _audioEngine!.panicStopSfx();
        break;

      case AppShortcutAction.toggleFullscreen:
        _isFullscreen = !_isFullscreen;
        LoggerService().info('ShortcutService: Fullscreen toggled to $_isFullscreen');
        notifyListeners();
        break;

      case AppShortcutAction.sfx1:
      case AppShortcutAction.sfx2:
      case AppShortcutAction.sfx3:
      case AppShortcutAction.sfx4:
      case AppShortcutAction.sfx5:
      case AppShortcutAction.sfx6:
      case AppShortcutAction.sfx7:
      case AppShortcutAction.sfx8:
      case AppShortcutAction.sfx9:
        final index = action.index - AppShortcutAction.sfx1.index;
        final triggers = _audioEngine!.sfxBus.triggers;
        if (index < triggers.length) {
          _audioEngine!.sfxBus.triggerSfx(triggers[index].id);
        }
        break;
    }
  }

  void handleActionDirectly(AppShortcutAction action) {
    _executeAction(action);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }
}
