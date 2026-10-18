import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/scene_package_service.dart';
import '../../domain/models/scene_model.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/tokens.dart';
import '../design/ds_button.dart';
import '../design/ds_dialog.dart';
import '../design/ds_field.dart';
import '../design/toast.dart';

/// Exports one scene as `.scene.zip` and reports the result with a toast.
Future<void> exportScene(BuildContext context, SceneModel scene) async {
  final l10n = AppLocalizations.of(context)!;
  final toasts = context.read<ToastController?>();
  try {
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: l10n.saveSceneAs,
      fileName: '${scene.name.replaceAll(RegExp(r'[^\w\s\-]'), '_')}.scene.zip',
      type: FileType.custom,
      allowedExtensions: ['zip', 'scene.zip'],
    );
    if (savePath != null) {
      await ScenePackageService().exportSingleScene(scene: scene, exportZipPath: savePath);
      toasts?.success(l10n.toastSceneExported, message: scene.name);
    }
  } catch (e) {
    toasts?.error(l10n.toastExportFailed, message: '$e');
  }
}

/// Exports all scenes as a `.pack.zip` bundle after asking for its name.
Future<void> exportScenePack(BuildContext context, List<SceneModel> scenes) async {
  final l10n = AppLocalizations.of(context)!;
  final toasts = context.read<ToastController?>();
  final titleController = TextEditingController(text: l10n.defaultPackTitle);
  final descController = TextEditingController(text: l10n.defaultPackDesc);

  final confirmed = await showDsDialog<bool>(
    context: context,
    builder: (ctx) => DsDialog(
      title: l10n.exportScenePackTitle,
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
          DsTextField(label: l10n.packTitleLabel, controller: titleController, autofocus: true),
          const SizedBox(height: Spacing.s4),
          DsTextField(label: l10n.packDescLabel, controller: descController),
        ],
      ),
    ),
  );

  if (confirmed != true) return;
  try {
    final title = titleController.text.trim();
    final sanitized = title.replaceAll(RegExp(r'[^\w\s\-]'), '_');
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: l10n.savePackAs,
      fileName: '$sanitized.pack.zip',
      type: FileType.custom,
      allowedExtensions: ['zip', 'pack.zip'],
    );
    if (savePath != null) {
      await ScenePackageService().exportPackPackage(
        scenes: scenes,
        exportZipPath: savePath,
        title: title,
        description: descController.text.trim(),
      );
      toasts?.success(l10n.toastBundleExported, message: title);
    }
  } catch (e) {
    toasts?.error(l10n.toastExportFailed, message: '$e');
  }
}
