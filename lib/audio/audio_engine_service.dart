import 'package:flutter/foundation.dart';
import 'music_bus_controller.dart';
import 'ambient_bus_controller.dart';
import 'sfx_bus_controller.dart';
import 'ducking_controller.dart';
import '../services/logger_service.dart';
import '../services/settings_service.dart';

class AudioEngineService extends ChangeNotifier {
  late final MusicBusController musicBus;
  late final AmbientBusController ambientBus;
  late final SfxBusController sfxBus;
  late final DuckingController duckingController;
  SettingsService? _settings;

  double _masterVolume = 1.0;
  final bool _isInitialized = true;

  bool get isInitialized => _isInitialized;
  double get masterVolume => _masterVolume;
  SettingsService? get settings => _settings;

  AudioEngineService({SettingsService? settings}) {
    _settings = settings;
    duckingController = DuckingController(
      duckedVolumeMultiplier: settings?.duckMultiplier ?? 0.4,
      attackDuration: settings?.duckAttackDuration ?? Duration.zero,
      releaseDuration: settings?.duckReleaseDuration ?? const Duration(milliseconds: 1200),
    );

    musicBus = MusicBusController();
    ambientBus = AmbientBusController();
    sfxBus = SfxBusController(
      onSfxTriggered: _handleSfxDucking,
    );

    musicBus.addListener(notifyListeners);
    ambientBus.addListener(notifyListeners);
    sfxBus.addListener(notifyListeners);
    _settings?.addListener(_onSettingsChanged);

    LoggerService().info('AudioEngineService initialized successfully!');
  }

  void attachSettings(SettingsService settings) {
    if (_settings == settings) return;
    _settings?.removeListener(_onSettingsChanged);
    _settings = settings;
    _settings?.addListener(_onSettingsChanged);
    _onSettingsChanged();
  }

  void _onSettingsChanged() {
    if (_settings != null) {
      duckingController.updateSettings(
        duckMultiplier: _settings!.duckMultiplier,
        attack: _settings!.duckAttackDuration,
        release: _settings!.duckReleaseDuration,
      );
    }
  }

  void setMasterVolume(double volume) {
    _masterVolume = volume.clamp(0.0, 1.0);
    musicBus.setVolume(musicBus.rawVolume);
    ambientBus.setMasterVolume(_masterVolume);
    sfxBus.setMasterVolume(_masterVolume);
    notifyListeners();
  }

  void _handleSfxDucking() {
    duckingController.triggerDuck(
      onVolumeUpdate: (multiplier) {
        musicBus.updateDuckingMultiplier(multiplier);
      },
    );
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _settings?.removeListener(_onSettingsChanged);
    musicBus.removeListener(notifyListeners);
    ambientBus.removeListener(notifyListeners);
    sfxBus.removeListener(notifyListeners);

    duckingController.dispose();
    musicBus.dispose();
    ambientBus.dispose();
    sfxBus.dispose();

    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }
}
