import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../services/logger_service.dart';

class LoggerConsoleDrawer extends StatelessWidget {
  const LoggerConsoleDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Consumer<LoggerService>(
      builder: (context, logger, _) {
        return Drawer(
          width: 450,
          child: Column(
            children: [
              AppBar(
                title: Text(
                  l10n?.logConsoleTitle ?? 'Log Console',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: l10n?.clearLogs ?? 'Clear logs',
                    onPressed: () => logger.clear(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Expanded(
                child: logger.logs.isEmpty
                    ? Center(child: Text(l10n?.noLogs ?? 'No logs', style: GoogleFonts.inter(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: logger.logs.length,
                        itemBuilder: (context, index) {
                          final log = logger.logs[index];
                          final color = _getColor(log.level);

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: Theme.of(context).cardColor,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '[${log.formattedTime}]',
                                        style: GoogleFonts.jetBrainsMono(fontSize: 10, color: Colors.grey),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: color.withAlpha(40),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          log.level.name.toUpperCase(),
                                          style: GoogleFonts.jetBrainsMono(fontSize: 10, color: color, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  SelectableText(
                                    log.message,
                                    style: GoogleFonts.jetBrainsMono(fontSize: 12),
                                  ),
                                  if (log.details != null) ...[
                                    const SizedBox(height: 4),
                                    SelectableText(
                                      log.details!,
                                      style: GoogleFonts.jetBrainsMono(fontSize: 11, color: Colors.redAccent),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getColor(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return Colors.blueAccent;
      case LogLevel.warning:
        return Colors.orangeAccent;
      case LogLevel.error:
        return Colors.redAccent;
    }
  }
}
