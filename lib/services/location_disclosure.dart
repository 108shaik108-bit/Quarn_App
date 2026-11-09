import 'package:flutter/material.dart';

/// Explains the location use before the app asks the operating system for access.
class LocationDisclosure {
  static Future<bool> show(BuildContext context) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Why Quarn App needs your location'),
        content: const Text(
          'If you choose to continue, Quarn App will use your device location to calculate local prayer times and the direction of the Qibla. Your selected coordinates are saved on this device so the app can remember your location and schedule optional prayer alarms. The current app version does not send these coordinates to a Quarn App server. You can choose a city manually instead, and you can deny or revoke location permission at any time in device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    return accepted == true;
  }
}
