import 'package:flutter/material.dart' hide Durations;
import 'package:provider/provider.dart';
import '../../audio/ambient_bus_controller.dart';
import '../../audio/audio_engine_service.dart';
import '../../audio/music_bus_controller.dart';
import '../../audio/sfx_bus_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/ds_theme.dart';
import '../../theme/tokens.dart';
import '../design/ds_button.dart';
import '../design/ds_icon.dart';
import '../design/ds_slider.dart';
import '../widgets/bus_equalizer.dart';
import 'shell_scope.dart';

/// Bottom mixer: current track, transport and the volume of every channel.
/// The only place where volume is set (layers keep their own slider).
class MixerBar extends StatelessWidget {
  const MixerBar({super.key});

  static const double _channelWidth = 150;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context)!;
    final music = context.watch<MusicBusController>();
    final ambient = context.watch<AmbientBusController>();
    final sfx = context.watch<SfxBusController>();
    final engine = context.watch<AudioEngineService>();
    final layout = ShellScope.maybeOf(context)?.layout ?? ShellLayout.of(MediaQuery.sizeOf(context).width);
    final wide = layout == ShellLayout.wide;

    final track = music.currentTrack;
    final playing = music.isPlaying;

    final now = Row(
      children: [
        Container(
          width: Sizes.targetMin,
          height: Sizes.targetMin,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ds.surfaceRaised,
            borderRadius: Radii.mdAll,
            border: Border.all(color: ds.border, width: Sizes.borderWidth),
          ),
          child: const DsIcon('music'),
        ),
        const SizedBox(width: Spacing.s3),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                track?.title ?? l10n.noMusic,
                style: ds.body.copyWith(fontWeight: FontWeight.w500, color: track == null ? ds.textMuted : ds.text),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (track != null)
                Row(
                  children: [
                    const MusicEqualizer(height: Spacing.s3),
                    const SizedBox(width: Spacing.s2),
                    Text(playing ? l10n.playing : l10n.paused, style: ds.caption),
                  ],
                ),
            ],
          ),
        ),
      ],
    );

    final transport = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DsButton.transport(
          key: const ValueKey('mixer_play_pause_button'),
          icon: playing ? 'pause' : 'play',
          label: playing ? l10n.pauseTooltip : l10n.playTooltip,
          hotkey: 'Space',
          onPressed: track == null
              ? null
              : () {
                  if (playing) {
                    music.pause();
                  } else {
                    music.resume();
                  }
                },
        ),
        const SizedBox(width: Spacing.s2),
        DsButton.ghost(
          key: const ValueKey('mixer_stop_button'),
          icon: 'stop',
          iconOnly: true,
          label: l10n.stopMusic,
          onPressed: track == null ? null : () => music.stop(),
        ),
      ],
    );

    Widget channel(String icon, String label, double value, ValueChanged<double> onChanged, {Key? key}) {
      return SizedBox(
        width: _channelWidth,
        child: DsSlider(key: key, icon: icon, value: value, onChanged: onChanged, semanticLabel: label),
      );
    }

    final master = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DsButton.ghost(
          key: const ValueKey('mixer_mute_button'),
          icon: engine.isMuted ? 'mute' : 'volume',
          iconOnly: true,
          label: engine.isMuted ? l10n.unmuteTooltip : l10n.muteTooltip,
          hotkey: 'M',
          onPressed: engine.toggleMute,
        ),
        SizedBox(
          width: _channelWidth - Sizes.icon - Spacing.s2,
          child: DsSlider(
            key: const ValueKey('mixer_master_slider'),
            value: engine.masterVolume,
            onChanged: engine.setMasterVolume,
            semanticLabel: l10n.master,
          ),
        ),
      ],
    );

    final channels = wide
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              channel('music', l10n.music, music.rawVolume, music.setVolume, key: const ValueKey('mixer_music_slider')),
              const SizedBox(width: Spacing.s3),
              channel('waves', l10n.ambient, ambient.channelVolume, ambient.setChannelVolume,
                  key: const ValueKey('mixer_ambient_slider')),
              const SizedBox(width: Spacing.s3),
              channel('bolt', l10n.sfx, sfx.rawVolume, sfx.setVolume, key: const ValueKey('mixer_sfx_slider')),
              const SizedBox(width: Spacing.s3),
              Container(width: Sizes.borderWidth, height: Spacing.s6, color: ds.border),
              const SizedBox(width: Spacing.s3),
              master,
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ChannelsPopover(
                label: l10n.channelVolumes,
                music: music,
                ambient: ambient,
                sfx: sfx,
              ),
              const SizedBox(width: Spacing.s2),
              master,
            ],
          );

    return Container(
      height: Sizes.mixerHeight,
      padding: EdgeInsets.symmetric(horizontal: layout == ShellLayout.compact ? Spacing.s3 : Spacing.s5),
      decoration: BoxDecoration(
        color: ds.surface,
        border: Border(top: BorderSide(color: ds.border, width: Sizes.borderWidth)),
      ),
      child: CustomMultiChildLayout(
        delegate: _MixerLayout(),
        children: [
          LayoutId(id: _MixerZone.now, child: now),
          LayoutId(id: _MixerZone.transport, child: transport),
          LayoutId(id: _MixerZone.channels, child: channels),
        ],
      ),
    );
  }
}

enum _MixerZone { now, transport, channels }

/// Three zones: the track on the left, transport in the centre of the bar,
/// channels on the right. When the channels reach past the centre (they
/// are wide below ~1400px) the transport moves left just enough to keep its
/// gap; the track takes what is left.
class _MixerLayout extends MultiChildLayoutDelegate {
  static const double transportGap = Spacing.s5;
  static const double nowGap = Spacing.s4;

  _MixerLayout();

  @override
  void performLayout(Size size) {
    final loose = BoxConstraints.loose(size);
    final channels = layoutChild(_MixerZone.channels, loose);
    final transport = layoutChild(_MixerZone.transport, loose);
    final latest = size.width - channels.width - transportGap - transport.width;
    final transportX = ((size.width - transport.width) / 2).clamp(0.0, latest < 0 ? 0.0 : latest);
    final now = layoutChild(
      _MixerZone.now,
      BoxConstraints(maxWidth: (transportX - nowGap).clamp(0.0, size.width), maxHeight: size.height),
    );
    positionChild(_MixerZone.channels, Offset(size.width - channels.width, (size.height - channels.height) / 2));
    positionChild(_MixerZone.transport, Offset(transportX, (size.height - transport.height) / 2));
    positionChild(_MixerZone.now, Offset(0, (size.height - now.height) / 2));
  }

  @override
  bool shouldRelayout(_MixerLayout oldDelegate) => false;
}

/// Music, Ambient and SFX sliders in a popover (medium and compact windows).
class _ChannelsPopover extends StatelessWidget {
  final String label;
  final MusicBusController music;
  final AmbientBusController ambient;
  final SfxBusController sfx;

  const _ChannelsPopover({required this.label, required this.music, required this.ambient, required this.sfx});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (buttonContext) => DsButton.ghost(
        key: const ValueKey('mixer_channels_button'),
        icon: 'settings',
        iconOnly: true,
        label: label,
        onPressed: () {
          final button = buttonContext.findRenderObject()! as RenderBox;
          final overlay = Overlay.of(buttonContext).context.findRenderObject()! as RenderBox;
          final topLeft = button.localToGlobal(Offset.zero, ancestor: overlay);
          final position = RelativeRect.fromLTRB(
            topLeft.dx,
            topLeft.dy - _ChannelsEntry.entryHeight - Spacing.s2,
            overlay.size.width - topLeft.dx - button.size.width,
            overlay.size.height - topLeft.dy,
          );
          showMenu<void>(
            context: buttonContext,
            position: position,
            constraints: const BoxConstraints(minWidth: _ChannelsEntry.entryWidth),
            items: const [_ChannelsEntry()],
          );
        },
      ),
    );
  }
}

class _ChannelsEntry extends PopupMenuEntry<void> {
  static const double entryWidth = 280;
  static const double entryHeight = Sizes.targetMin * 3 + Spacing.s2;

  const _ChannelsEntry();

  @override
  double get height => entryHeight;

  @override
  bool represents(void value) => false;

  @override
  State<_ChannelsEntry> createState() => _ChannelsEntryState();
}

class _ChannelsEntryState extends State<_ChannelsEntry> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final music = context.watch<MusicBusController>();
    final ambient = context.watch<AmbientBusController>();
    final sfx = context.watch<SfxBusController>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.s3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DsSlider(icon: 'music', value: music.rawVolume, onChanged: music.setVolume, semanticLabel: l10n.music),
          DsSlider(
            icon: 'waves',
            value: ambient.channelVolume,
            onChanged: ambient.setChannelVolume,
            semanticLabel: l10n.ambient,
            ringColor: context.ds.surfaceRaised,
          ),
          DsSlider(icon: 'bolt', value: sfx.rawVolume, onChanged: sfx.setVolume, semanticLabel: l10n.sfx),
        ],
      ),
    );
  }
}
