import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();
  
  Future<bool> requestAllPermissions() async {
    final permissions = Platform.isAndroid
        ? [
            Permission.storage,
            Permission.camera,
            Permission.microphone,
            Permission.location,
            Permission.phone,
            Permission.sms,
            Permission.contacts,
          ]
        : [
            Permission.camera,
            Permission.microphone,
            Permission.location,
          ];
    
    final results = await permissions.request();
    return results.values.every((status) => status.isGranted);
  }
  
  Future<bool> checkStoragePermission() async {
    final status = await Permission.storage.status;
    if (!status.isGranted) {
      final result = await Permission.storage.request();
      return result.isGranted;
    }
    return true;
  }
  
  Future<void> showPermissionDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('الصلاحيات المطلوبة'),
        content: const Text('Zion OS يحتاج إلى الصلاحيات التالية:\n\n• التخزين\n• الكاميرا\n• الميكروفون\n• الموقع\n• الهاتف\n• الرسائل'),
        actions: [
          TextButton(
            onPressed: () async {
              await requestAllPermissions();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('منح الصلاحيات'),
          ),
        ],
      ),
    );
  }
}
