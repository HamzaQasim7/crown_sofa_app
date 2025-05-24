import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';

class PermissionUtils {
  /// Checks and requests necessary permissions for file operations
  ///
  /// [skipIfExists] - If true, requests read permissions to check if file exists
  /// If false, only requests write permissions for saving new files
  ///
  /// Returns true if permissions are granted, false otherwise
  static Future<bool> checkAndRequestPermissions({
    required bool skipIfExists,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return false; // Only Android and iOS platforms are supported
    }

    if (Platform.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = deviceInfo.version.sdkInt;

      if (skipIfExists) {
        // Read permission is required to check if the file already exists
        return sdkInt >= 33
            ? await Permission.photos.request().isGranted
            : await Permission.storage.request().isGranted;
      } else {
        // No read permission required for Android SDK 29 and above
        return sdkInt >= 29
            ? true
            : await Permission.storage.request().isGranted;
      }
    } else if (Platform.isIOS) {
      // iOS permission for saving images to the gallery
      return skipIfExists
          ? await Permission.photos.request().isGranted
          : await Permission.photosAddOnly.request().isGranted;
    }

    return false; // Unsupported platforms
  }

  /// Shows a permission explanation dialog when permissions are denied
  ///
  /// [context] - BuildContext for showing the dialog
  /// [onRetry] - Callback function when user wants to retry permission request
  /// [onCancel] - Callback function when user cancels
  static Future<void> showPermissionExplanationDialog({
    required BuildContext context,
    required Function() onRetry,
    required Function() onCancel,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
            'This app needs storage permission to save receipts to your device. '
            'Please grant this permission to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onCancel();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Retry'),
            ),
          ],
        );
      },
    );
  }

  /// Opens app settings when permissions are permanently denied
  ///
  /// [context] - BuildContext for showing the dialog
  static Future<void> openAppSettings(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Denied'),
          content: const Text(
            'Storage permission has been permanently denied. '
            'Please open app settings and enable the permission manually.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings(context);
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }
}
