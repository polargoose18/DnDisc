import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../audio/audio_engine_service.dart';
import '../../audio/music_bus_controller.dart';
import '../../domain/models/scene_model.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/tokens.dart';
import '../design/ds_button.dart';
import '../design/ds_dialog.dart';
import '../design/ds_field.dart';
import '../design/ds_panel.dart';
import '../view_models/media_library_view_model.dart';
import '../view_models/scene_view_model.dart';
import 'create_edit_scene_dialog.dart';
import 'scene_card.dart';
import 'scene_export_actions.dart';

/// Left panel: scene search and list.
class SceneSelectorPanel extends StatefulWidget {
  const SceneSelectorPanel({super.key});

  @override
  State<SceneSelectorPanel> createState() => _SceneSelectorPanelState();
}

class _SceneSelectorPanelState extends State<SceneSelectorPanel> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _create(SceneViewModel scenes) async {
    final scene = await showDsDialog<SceneModel>(context: context, builder: (_) => const CreateEditSceneDialog());
    if (scene != null) await scenes.createScene(scene);
  }

  Future<void> _edit(SceneViewModel scenes, SceneModel scene) async {
    final updated = await showDsDialog<SceneModel>(context: context, builder: (_) => CreateEditSceneDialog(scene: scene));
    if (updated != null) await scenes.updateScene(updated);
  }

  Future<void> _delete(SceneViewModel scenes, SceneModel scene) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await confirmDelete(
      context,
      title: l10n.deleteSceneTitle,
      message: l10n.deleteSceneMessage(scene.name),
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
      closeLabel: l10n.close,
    );
    if (confirmed) await scenes.deleteScene(scene.id);
  }

  @override
  Widget build(BuildContext context) {
    final scenes = context.watch<SceneViewModel>();
    final library = context.watch<MediaLibraryViewModel>();
    final engine = context.watch<AudioEngineService>();
    final playing = context.select<MusicBusController, bool>((m) => m.isPlaying);
    final l10n = AppLocalizations.of(context)!;

    final all = scenes.scenes;
    final shown = _query.isEmpty
        ? all
        : all.where((s) => s.name.toLowerCase().contains(_query) || s.description.toLowerCase().contains(_query)).toList();

    final Widget list;
    if (all.isEmpty) {
      list = DsEmptyState(
        icon: 'scene',
        title: l10n.noScenesTitle,
        message: l10n.noScenesHint,
        action: DsButton.primary(label: l10n.createSceneBtn, icon: 'plus', onPressed: () => _create(scenes)),
      );
    } else if (shown.isEmpty) {
      list = DsEmptyState(
        icon: 'search',
        title: l10n.noScenesFoundTitle,
        message: l10n.noScenesMatching,
        action: DsButton(
          label: l10n.clearSearch,
          onPressed: () {
            _search.clear();
            setState(() => _query = '');
          },
        ),
      );
    } else {
      list = ListView.separated(
        itemCount: shown.length,
        separatorBuilder: (_, __) => const SizedBox(height: Spacing.s1),
        itemBuilder: (context, index) {
          final scene = shown[index];
          return SceneCard(
            key: ValueKey('scene_card_${scene.id}'),
            scene: scene,
            isActive: scene.id == scenes.activeSceneId,
            playing: playing,
            onActivate: () => scenes.activateScene(scene, audioEngine: engine, mediaLibrary: library.service),
            onEdit: () => _edit(scenes, scene),
            onDuplicate: () => scenes.duplicateScene(scene.id),
            onDelete: () => _delete(scenes, scene),
            onExport: () => exportScene(context, scene),
          );
        },
      );
    }

    return DsPanel(
      expand: true,
      padding: const EdgeInsets.all(Spacing.s4),
      title: l10n.scenesTitle,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DsButton.ghost(
            key: const ValueKey('export_scene_pack_btn'),
            icon: 'archive',
            iconOnly: true,
            label: l10n.exportBundleTooltip,
            onPressed: all.isEmpty ? null : () => exportScenePack(context, all),
          ),
          DsButton.ghost(
            key: const ValueKey('create_scene_btn'),
            icon: 'plus',
            iconOnly: true,
            label: l10n.createSceneBtn,
            onPressed: () => _create(scenes),
          ),
        ],
      ),
      child: Column(
        children: [
          DsTextField(
            controller: _search,
            icon: 'search',
            placeholder: l10n.searchScenesPlaceholder,
            clearable: true,
            clearLabel: l10n.clearSearch,
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
          const SizedBox(height: Spacing.s3),
          Expanded(child: list),
        ],
      ),
    );
  }
}
