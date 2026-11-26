import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' hide Durations;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../audio/ambient_bus_controller.dart';
import '../../audio/audio_engine_service.dart';
import '../../audio/music_bus_controller.dart';
import '../../data/services/audio_file_picker.dart';
import '../../data/services/media_library_service.dart';
import '../../data/services/media_package_service.dart';
import '../../domain/models/library_track.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/ds_theme.dart';
import '../../theme/tokens.dart';
import '../design/ds_button.dart';
import '../design/ds_controls.dart';
import '../design/ds_dialog.dart';
import '../design/ds_field.dart';
import '../design/ds_panel.dart';
import '../design/toast.dart';
import '../shell/top_bar.dart';
import '../view_models/media_library_view_model.dart';
import '../widgets/import_track_dialog.dart';
import '../widgets/track_pick_list.dart';
import '../widgets/track_row.dart';

/// Media Library: search, type filter with counts and the track list.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final Map<String, bool> _fileExists = {};
  bool _dragging = false;

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  /// Checks the files of [tracks] once; rows grey out when a file is gone.
  void _checkFiles(List<LibraryTrack> tracks) {
    for (final track in tracks) {
      final key = '${track.id}|${track.filePath}';
      if (_fileExists.containsKey(key)) continue;
      _fileExists[key] = true;
      File(track.filePath).exists().then((exists) {
        if (mounted && !exists) setState(() => _fileExists[key] = false);
      });
    }
  }

  bool _isMissing(LibraryTrack track) => _fileExists['${track.id}|${track.filePath}'] == false;

  Future<void> _import(MediaLibraryViewModel library, {List<String> paths = const [], AudioBusType? bus}) async {
    final l10n = AppLocalizations.of(context)!;
    final toasts = context.read<ToastController?>();
    final selection = await showDsDialog<ImportSelection>(
      context: context,
      builder: (_) => ImportAudioDialog(initialPaths: paths, initialBus: bus ?? library.activeBusFilter ?? AudioBusType.music),
    );
    if (selection == null) return;
    try {
      final imported = await library.importPaths(busType: selection.busType, paths: selection.paths);
      if (imported.isNotEmpty) toasts?.success(l10n.toastImported(imported.length));
    } catch (e) {
      toasts?.error(l10n.toastExportFailed, message: '$e');
    }
  }

  void _onDrop(MediaLibraryViewModel library, List<String> paths) {
    final l10n = AppLocalizations.of(context)!;
    final supported = paths.where(MediaLibraryService.isSupportedFile).toList();
    final skipped = paths.length - supported.length;
    if (skipped > 0) context.read<ToastController?>()?.show(title: l10n.toastImportSkipped(skipped));
    if (supported.isNotEmpty) _import(library, paths: supported);
  }

  Future<void> _togglePlay(LibraryTrack track, MediaLibraryViewModel library, AudioEngineService engine, bool playing) async {
    if (playing) {
      switch (track.busType) {
        case AudioBusType.music:
          await engine.musicBus.stop();
        case AudioBusType.ambient:
          await engine.ambientBus.toggleLayer(track.id);
        case AudioBusType.sfx:
          break;
      }
    } else {
      library.playTrackToEngine(track, engine);
    }
  }

  Future<void> _edit(LibraryTrack track, MediaLibraryViewModel library) async {
    final updated = await showDsDialog<LibraryTrack>(context: context, builder: (_) => EditTrackDialog(track: track));
    if (updated != null) await library.updateTrack(updated);
  }

  Future<void> _delete(LibraryTrack track, MediaLibraryViewModel library) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await confirmDelete(
      context,
      title: l10n.deleteTrackTitle,
      message: l10n.deleteTrackMessage(track.title),
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
      closeLabel: l10n.close,
    );
    if (confirmed) await library.deleteTrack(track.id);
  }

  Future<void> _locate(LibraryTrack track, MediaLibraryViewModel library) async {
    final picked = await AudioFilePicker.pick();
    if (picked.paths.isNotEmpty) await library.updateTrack(track.copyWith(filePath: picked.paths.single));
  }

  Future<void> _exportSet(MediaLibraryViewModel library) async {
    final l10n = AppLocalizations.of(context)!;
    final toasts = context.read<ToastController?>();
    final title = TextEditingController(text: l10n.defaultMediaPackageName);
    final description = TextEditingController(text: l10n.defaultMediaPackageDesc);

    final confirmed = await showDsDialog<bool>(
      context: context,
      builder: (ctx) => DsDialog(
        title: l10n.exportMediaPackageTitle,
        icon: 'archive',
        size: DsDialogSize.sm,
        closeLabel: l10n.close,
        onClose: () => Navigator.of(ctx).pop(false),
        actions: [
          DsButton.ghost(label: l10n.cancel, onPressed: () => Navigator.of(ctx).pop(false)),
          DsButton.primary(label: l10n.exportAction, icon: 'archive', onPressed: () => Navigator.of(ctx).pop(true)),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DsTextField(label: l10n.mediaPackageNameLabel, controller: title, autofocus: true),
            const SizedBox(height: Spacing.s4),
            DsTextField(label: l10n.mediaPackageDescLabel, controller: description),
          ],
        ),
      ),
    );
    if (confirmed != true) return;

    try {
      final name = title.text.trim();
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: l10n.saveMediaPackageAs,
        fileName: '${name.replaceAll(RegExp(r'[^\w\s\-]'), '_')}.media.zip',
        type: FileType.custom,
        allowedExtensions: ['zip', 'media.zip'],
      );
      if (savePath != null) {
        await MediaPackageService().exportMediaPackage(
          tracks: library.allTracks,
          exportZipPath: savePath,
          title: name,
          description: description.text.trim(),
        );
        toasts?.success(l10n.toastMediaPackageExported, message: name);
      }
    } catch (e) {
      toasts?.error(l10n.toastExportFailed, message: '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context)!;
    final library = context.watch<MediaLibraryViewModel>();
    final engine = context.read<AudioEngineService>();
    // Ducking makes the music bus notify every ~30 ms; only the playing
    // state and the current track matter here.
    final (musicPlaying, musicTrackId) =
        context.select<MusicBusController, (bool, String?)>((m) => (m.isPlaying, m.currentTrack?.id));
    final ambient = context.watch<AmbientBusController>();

    final all = library.allTracks;
    final tracks = library.tracks;
    _checkFiles(tracks);

    int count(AudioBusType? bus) => bus == null ? all.length : all.where((t) => t.busType == bus).length;

    bool isPlaying(LibraryTrack t) => switch (t.busType) {
          AudioBusType.music => musicPlaying && musicTrackId == t.id,
          AudioBusType.ambient => ambient.layers.any((l) => l.id == t.id && l.isActive),
          AudioBusType.sfx => false,
        };

    final filter = DsSegmentedControl<AudioBusType?>(
      label: l10n.tabLibrary,
      value: library.activeBusFilter,
      onChanged: library.setBusFilter,
      options: [
        DsSegment(id: null, label: '${l10n.filterAll} · ${count(null)}'),
        for (final bus in AudioBusType.values) DsSegment(id: bus, label: '${trackKindLabel(l10n, bus)} · ${count(bus)}'),
      ],
    );

    final searchField = DsTextField(
      key: const ValueKey('library_search_input'),
      controller: _search,
      focusNode: _searchFocus,
      icon: 'search',
      placeholder: l10n.searchPlaceholder,
      hotkey: 'Ctrl K',
      clearable: true,
      clearLabel: l10n.clearSearch,
      onChanged: library.setSearchQuery,
    );

    final Widget list;
    if (library.isLoading && all.isEmpty) {
      list = const Center(child: CircularProgressIndicator());
    } else if (all.isEmpty) {
      list = DsEmptyState(
        icon: 'library',
        title: l10n.libraryEmpty,
        message: l10n.libraryEmptyHint,
        action: DsButton.primary(key: const ValueKey('import_empty_button'), label: l10n.importFilesBtn, icon: 'upload', onPressed: () => _import(library)),
      );
    } else if (tracks.isEmpty) {
      list = DsEmptyState(
        icon: 'search',
        title: l10n.noTracksFound,
        message: l10n.noTracksFoundHint,
        action: DsButton(
          label: l10n.clearSearch,
          onPressed: () {
            _search.clear();
            library.setSearchQuery('');
            library.setBusFilter(null);
          },
        ),
      );
    } else {
      list = ListView.builder(
        itemCount: tracks.length,
        itemBuilder: (context, index) {
          final track = tracks[index];
          final playing = isPlaying(track);
          return TrackRow(
            key: ValueKey('library_track_card_${track.id}'),
            track: track,
            playing: playing,
            missing: _isMissing(track),
            onPlay: () => _togglePlay(track, library, engine, playing),
            onEdit: () => _edit(track, library),
            onDelete: () => _delete(track, library),
            onLocate: () => _locate(track, library),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: Palette.transparent,
      body: CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.keyK, control: true): _searchFocus.requestFocus},
        child: Focus(
          autofocus: true,
          child: Column(
            children: [
              TopBar(
                title: l10n.tabLibrary,
                navigationLabel: l10n.openNavigation,
                actions: [
                  DsButton(
                    key: const ValueKey('export_media_package_button'),
                    label: l10n.exportMediaPackageBtn,
                    icon: 'archive',
                    onPressed: all.isEmpty ? null : () => _exportSet(library),
                  ),
                  DsButton.primary(
                    key: const ValueKey('import_media_button'),
                    label: l10n.importBtn,
                    icon: 'upload',
                    onPressed: () => _import(library),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.s4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LayoutBuilder(
                        builder: (context, c) => c.maxWidth >= 800
                            ? Row(children: [Expanded(child: searchField), const SizedBox(width: Spacing.s4), filter])
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  searchField,
                                  const SizedBox(height: Spacing.s3),
                                  SingleChildScrollView(scrollDirection: Axis.horizontal, child: filter),
                                ],
                              ),
                      ),
                      const SizedBox(height: Spacing.s4),
                      Expanded(
                        child: DropTarget(
                          onDragEntered: (_) => setState(() => _dragging = true),
                          onDragExited: (_) => setState(() => _dragging = false),
                          onDragDone: (d) {
                            setState(() => _dragging = false);
                            _onDrop(library, d.files.map((f) => f.path).toList());
                          },
                          child: AnimatedContainer(
                            duration: Durations.fast,
                            decoration: BoxDecoration(
                              color: _dragging ? ds.primarySubtle : ds.surface,
                              borderRadius: Radii.lgAll,
                              border: Border.all(color: _dragging ? ds.primary : ds.border, width: Sizes.borderWidth),
                            ),
                            padding: const EdgeInsets.all(Spacing.s2),
                            child: list,
                          ),
                        ),
                      ),
                    ],
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
