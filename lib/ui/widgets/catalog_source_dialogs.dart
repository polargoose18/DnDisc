import 'package:flutter/material.dart';
import '../../domain/models/scene_repository_model.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/ds_theme.dart';
import '../../theme/tokens.dart';
import '../design/ds_button.dart';
import '../design/ds_dialog.dart';
import '../design/ds_field.dart';
import '../design/ds_icon.dart';
import '../design/ds_panel.dart';
import '../design/toast.dart';
import 'package:provider/provider.dart';
import '../view_models/repository_view_model.dart';

/// Add a catalog source, or edit one when [repo] is given. The URL is
/// checked before saving; errors say how to fix them.
class SourceFormDialog extends StatefulWidget {
  final SceneRepositoryModel? repo;

  const SourceFormDialog({super.key, this.repo});

  @override
  State<SourceFormDialog> createState() => _SourceFormDialogState();
}

class _SourceFormDialogState extends State<SourceFormDialog> {
  late final TextEditingController _url = TextEditingController(text: widget.repo?.url ?? '');
  late final TextEditingController _name = TextEditingController(text: widget.repo?.name ?? '');
  late final TextEditingController _description = TextEditingController(text: widget.repo?.description ?? '');
  bool _submitted = false;
  bool _saving = false;

  @override
  void dispose() {
    _url.dispose();
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  String? _urlError(AppLocalizations l10n) {
    final value = _url.text.trim();
    if (value.isEmpty) return l10n.enterSourceUrl;
    if (!value.startsWith('http://') && !value.startsWith('https://')) return l10n.urlHttpPrefixValidation;
    return null;
  }

  String? _nameError(AppLocalizations l10n) =>
      widget.repo != null && _name.text.trim().isEmpty ? l10n.enterSourceName : null;

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _submitted = true);
    if (_urlError(l10n) != null || _nameError(l10n) != null) return;

    final vm = context.read<RepositoryViewModel>();
    final toasts = context.read<ToastController?>();
    setState(() => _saving = true);
    final repo = widget.repo;
    final success = repo == null
        ? await vm.addRepository(name: _name.text, url: _url.text, description: _description.text)
        : await vm.updateRepository(id: repo.id, name: _name.text, url: _url.text, description: _description.text);
    if (!mounted) return;
    Navigator.of(context).pop();
    if (!success && vm.errorMessage != null) toasts?.error(l10n.toastInstallFailed, message: vm.errorMessage);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final editing = widget.repo != null;
    return DsDialog(
      title: editing ? l10n.editSourceTitle : l10n.addSourceTitle,
      icon: 'catalog',
      closeLabel: l10n.close,
      actions: [
        DsButton.ghost(label: l10n.cancel, onPressed: () => Navigator.of(context).pop()),
        DsButton.primary(
          key: const ValueKey('save_source_btn'),
          label: editing ? l10n.saveBtn : l10n.addSourceBtn,
          icon: editing ? 'check' : 'plus',
          onPressed: _saving ? null : _save,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DsTextField(
            key: const ValueKey('source_url_field'),
            label: l10n.sourceUrlLabel,
            controller: _url,
            placeholder: l10n.sourceUrlHint,
            autofocus: true,
            error: _submitted ? _urlError(l10n) : null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Spacing.s5),
          DsTextField(
            key: const ValueKey('source_name_field'),
            label: l10n.sourceNameLabel,
            controller: _name,
            hint: editing ? null : l10n.sourceNameHint,
            error: _submitted ? _nameError(l10n) : null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Spacing.s5),
          DsTextField(label: l10n.sourceDescLabel, controller: _description),
        ],
      ),
    );
  }
}

/// List of connected sources with edit and remove.
class SourcesDialog extends StatelessWidget {
  const SourcesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context)!;
    final vm = context.watch<RepositoryViewModel>();
    final repos = vm.repositories;

    return DsDialog(
      title: l10n.sourcesDialogTitle,
      description: l10n.sourcesDialogDesc,
      icon: 'settings',
      closeLabel: l10n.close,
      actions: [
        DsButton.primary(
          label: l10n.addSourceBtn,
          icon: 'plus',
          onPressed: () => showDsDialog<void>(context: context, builder: (_) => const SourceFormDialog()),
        ),
      ],
      child: repos.isEmpty
          ? DsEmptyState(icon: 'catalog', title: l10n.noSourcesTitle, message: l10n.noSourcesHint)
          : Column(
              children: [
                for (final repo in repos)
                  Container(
                    constraints: const BoxConstraints(minHeight: Sizes.rowMin),
                    padding: const EdgeInsets.symmetric(vertical: Spacing.s2),
                    child: Row(
                      children: [
                        Container(
                          width: Sizes.sceneThumb,
                          height: Sizes.sceneThumb,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: ds.surfaceRaised,
                            borderRadius: Radii.mdAll,
                            border: Border.all(color: ds.border, width: Sizes.borderWidth),
                          ),
                          child: const DsIcon('catalog'),
                        ),
                        const SizedBox(width: Spacing.s3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(repo.name, style: ds.body.copyWith(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(repo.url, style: ds.code, maxLines: 1, overflow: TextOverflow.ellipsis),
                              if (vm.manifests[repo.id] != null)
                                Text(
                                  l10n.sourceStats(
                                    vm.manifests[repo.id]!.scenes.length,
                                    vm.manifests[repo.id]!.media.length,
                                    vm.manifests[repo.id]!.packs.length,
                                  ),
                                  style: ds.caption,
                                ),
                            ],
                          ),
                        ),
                        DsButton.ghost(
                          icon: 'edit',
                          iconOnly: true,
                          label: l10n.editDetails,
                          onPressed: () => showDsDialog<void>(context: context, builder: (_) => SourceFormDialog(repo: repo)),
                        ),
                        DsButton.ghost(
                          icon: 'trash',
                          iconOnly: true,
                          label: l10n.delete,
                          onPressed: () async {
                            final confirmed = await confirmDelete(
                              context,
                              title: l10n.deleteSourceTitle,
                              message: l10n.deleteSourceMessage(repo.name),
                              confirmLabel: l10n.delete,
                              cancelLabel: l10n.cancel,
                              closeLabel: l10n.close,
                            );
                            if (confirmed) await vm.deleteRepository(repo.id);
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
