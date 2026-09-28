import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class StoragePermissionService {
  static final StoragePermissionService _instance = StoragePermissionService._internal();
  factory StoragePermissionService() => _instance;
  StoragePermissionService._internal();

  Future<bool> requestStoragePermission(BuildContext context) async {
    if (Platform.isAndroid) {
      if (await _isAndroid11OrHigher()) {
        final status = await Permission.manageExternalStorage.request();
        if (status.isGranted) return true;
        
        if (context.mounted) {
          await _showPermissionDialog(context);
        }
        return false;
      } else {
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    }
    return true;
  }

  Future<bool> _isAndroid11OrHigher() async {
    if (Platform.isAndroid) {
      final androidInfo = await _getAndroidVersion();
      return androidInfo >= 30;
    }
    return false;
  }

  Future<int> _getAndroidVersion() async {
    return int.tryParse(Platform.operatingSystemVersion.split('.').first) ?? 0;
  }

  Future<void> _showPermissionDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('صلاحية التخزين المطلوبة'),
        content: const Text(
          'Zion OS يحتاج إلى صلاحية الوصول الكامل للتخزين '
          'لعرض وإدارة جميع ملفات جهازك بشكل صحيح.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    );
  }

  Future<List<String>> getStorageDirectories() async {
    List<String> directories = [];
    
    try {
      // الوصول إلى المجلدات الرئيسية
      if (Platform.isAndroid) {
        directories.add('/storage/emulated/0/Download');
        directories.add('/storage/emulated/0/Documents');
        directories.add('/storage/emulated/0/Pictures');
        directories.add('/storage/emulated/0/DCIM');
        directories.add('/storage/emulated/0/Music');
        directories.add('/storage/emulated/0/Movies');
        directories.add('/storage/emulated/0/Android');
        
        // استخدام path_provider للمسارات الآمنة
        final appDir = await getApplicationDocumentsDirectory();
        directories.add(appDir.path);
      }
    } catch (e) {
      print('Error getting directories: $e');
    }
    
    return directories;
  }

  Future<bool> hasStoragePermission() async {
    if (Platform.isAndroid) {
      if (await _isAndroid11OrHigher()) {
        return await Permission.manageExternalStorage.isGranted;
      } else {
        return await Permission.storage.isGranted;
      }
    }
    return true;
  }

  Future<void> openAppSettingsPage() async {
    await openAppSettings();
  }
}
