import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/logger_service.dart';
import '../../theme/ds_theme.dart';
import '../../theme/tokens.dart';
import '../design/ds_button.dart';
import '../design/ds_controls.dart';

/// Log console: one mono line per entry with time, level word and message.
class LoggerConsoleDrawer extends StatelessWidget {
  const LoggerConsoleDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context)!;

    return Consumer<LoggerService>(
      builder: (context, logger, _) {
        return Drawer(
          width: Sizes.dialogSm,
          backgroundColor: ds.surface,
          shape: const RoundedRectangleBorder(),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(Spacing.s5, Spacing.s3, Spacing.s3, Spacing.s3),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: ds.border, width: Sizes.borderWidth)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(l10n.logConsoleTitle, style: ds.titleLg)),
                      DsButton.ghost(
                        icon: 'trash',
                        iconOnly: true,
                        label: l10n.clearLogs,
                        onPressed: logger.logs.isEmpty ? null : logger.clear,
                      ),
                      DsButton.ghost(
                        icon: 'x',
                        iconOnly: true,
                        label: l10n.close,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: logger.logs.isEmpty
                      ? Center(child: Text(l10n.noLogs, style: ds.body.copyWith(color: ds.textMuted)))
                      : ListView.separated(
                          padding: const EdgeInsets.all(Spacing.s4),
                          itemCount: logger.logs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: Spacing.s3),
                          itemBuilder: (context, index) {
                            final log = logger.logs[index];
                            final error = log.level == LogLevel.error;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(log.formattedTime, style: ds.code),
                                    const SizedBox(width: Spacing.s2),
                                    DsBadge(log.level.name.toUpperCase(), tone: error ? DsTone.danger : DsTone.neutral),
                                  ],
                                ),
                                const SizedBox(height: Spacing.s1),
                                SelectableText(log.message, style: ds.code.copyWith(color: ds.text)),
                                if (log.details != null)
                                  SelectableText(log.details!, style: ds.code.copyWith(color: error ? ds.danger : ds.textMuted)),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
