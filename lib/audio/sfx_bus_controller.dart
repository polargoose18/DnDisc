import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/sfx_trigger.dart';
import '../services/logger_service.dart';

class SfxBusController extends ChangeNotifier {
  final List<SfxTrigger> _triggers = [];
  double _masterSfxVolume = 1.0;
  final Function()? onSfxTriggered;

  SfxBusController({this.onSfxTriggered});

  List<SfxTrigger> get triggers => List.unmodifiable(_triggers);
  double get masterVolume => _masterSfxVolume;

  void addTrigger(SfxTrigger trigger) {
    if (!_triggers.any((t) => t.id == trigger.id)) {
      _triggers.add(trigger);
      notifyListeners();
    }
  }

  Future<void> triggerSfx(String triggerId) async {
    final index = _triggers.indexWhere((t) => t.id == triggerId);
    if (index != -1) {
      final trigger = _triggers[index];
      onSfxTriggered?.call();

      final file = File(trigger.filePath);
      if (!file.existsSync()) {
        LoggerService().warning('SfxBus: File does not exist', details: 'Path: ${trigger.filePath}');
        notifyListeners();
        return;
      }

      try {
        final player = AudioPlayer();
        await player.setVolume(trigger.volume * _masterSfxVolume);
        await player.setReleaseMode(ReleaseMode.stop);

        LoggerService().info('SfxBus: Triggering SFX "${trigger.title}"');
        await player.play(DeviceFileSource(file.path));

        // Auto dispose player after completion
        player.onPlayerComplete.listen((_) {
          player.dispose();
        });
      } catch (e, stack) {
        LoggerService().error('SfxBus: Exception triggering ${trigger.title}', details: '$e\n$stack');
      }
      notifyListeners();
    }
  }

  void setMasterVolume(double volume) {
    _masterSfxVolume = volume.clamp(0.0, 1.0);
    notifyListeners();
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }
}
