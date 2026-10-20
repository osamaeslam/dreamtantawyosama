import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/connectivity_service.dart';
import '../services/offline_queue_service.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

/// A persistent status bar shown at the top of every screen.
///
/// Displays the current [ConnectionStatus] icon + label, and the number of
/// pending queued actions. Tapping navigates to the [SyncQueueScreen].
///
/// To use globally, wrap your Scaffold body with this widget, or embed it
/// in an AppBar / persistent header.
class ConnectionStatusBar extends StatelessWidget {
  final VoidCallback? onTap;

  const ConnectionStatusBar({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<ConnectionStatus>(
      stream: ConnectivityService.instance.watchStatus(),
      initialData: ConnectivityService.instance.currentStatus,
      builder: (context, snapshot) {
        final status = snapshot.data ?? ConnectionStatus.checking;
        final pending = context.watch<OfflineQueueService>().totalPendingAndProcessing;
        final hasPending = pending > 0;

        final (icon, label, color) = _describe(status, isDark);

        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            color: color.withOpacity(0.12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (hasPending)
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.roseRed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$pending',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ),
      },
    );
  }

  (IconData, String, Color) _describe(ConnectionStatus status, bool isDark) {
    switch (status) {
      case ConnectionStatus.online:
        return (Icons.wifi, 'متصل بالخادم', AppTheme.emeraldGreen);
      case ConnectionStatus.offline:
        return (Icons.cloud_off, 'غير متصل بالخادم', AppTheme.roseRed);
      case ConnectionStatus.disconnected:
        return (Icons.signal_wifi_statusbar_connected_no_internet_rounded,
            'بدون اتصال', AppTheme.roseRed);
      case ConnectionStatus.checking:
        return (Icons.sync, 'جاري فحص الاتصال...', AppTheme.infoBlue);
    }
  }
}
