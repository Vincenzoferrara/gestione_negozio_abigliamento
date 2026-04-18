import 'package:flutter/material.dart';

import '../theme/theme.dart';

final GlobalKey<ScaffoldMessengerState> notificationMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  void messageBar(String type, String nameTab, String message) {
    final messenger = notificationMessengerKey.currentState;
    final context = notificationMessengerKey.currentContext;
    if (messenger == null || context == null) return;

    final style = _resolveStyle(context, type);
    final mediaQuery = MediaQuery.maybeOf(context);
    final screenHeight = mediaQuery?.size.height ?? 800;
    final topMargin = (mediaQuery?.padding.top ?? 0) + 12;
    final bottomMargin = screenHeight > 180
        ? screenHeight - topMargin - 104
        : 16.0;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(style.icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nameTab,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _cleanMessage(message),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: style.color,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(16, topMargin, 16, bottomMargin),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: style.duration,
        ),
      );
  }

  _MessageBarStyle _resolveStyle(BuildContext context, String type) {
    final appColors = Theme.of(context).extension<AppColorExtension>();
    final normalizedType = type.trim().toLowerCase();

    switch (normalizedType) {
      case 'successo':
        return _MessageBarStyle(
          color: appColors?.successColor ?? Colors.green,
          icon: Icons.check_circle,
          duration: const Duration(seconds: 4),
        );
      case 'warning':
      case 'partial':
        return _MessageBarStyle(
          color: appColors?.warningColor ?? Colors.orange,
          icon: Icons.warning_amber_rounded,
          duration: const Duration(seconds: 6),
        );
      case 'info':
        return _MessageBarStyle(
          color: Theme.of(context).colorScheme.primary,
          icon: Icons.info,
          duration: const Duration(seconds: 4),
        );
      case 'errore':
      default:
        return _MessageBarStyle(
          color: appColors?.errorColorStatus ?? Colors.red,
          icon: Icons.error_outline,
          duration: const Duration(seconds: 6),
        );
    }
  }

  String _cleanMessage(String message) {
    final trimmed = message.trim();
    if (trimmed.startsWith('Exception:')) {
      return trimmed.substring('Exception:'.length).trim();
    }
    return trimmed;
  }
}

class _MessageBarStyle {
  const _MessageBarStyle({
    required this.color,
    required this.icon,
    required this.duration,
  });

  final Color color;
  final IconData icon;
  final Duration duration;
}
