import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/magiczionos/magiczionos_provider.dart';
import '../../core/magiczionos/installers/rootfs_downloader.dart';

class MagiczionosInstallerScreen extends StatelessWidget {
  const MagiczionosInstallerScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MagiczionosProvider()..initialize(),
      child: Consumer<MagiczionosProvider>(builder: (context, provider, _) => Scaffold(
        appBar: AppBar(title: const Text('#magiczionos — التثبيت الحقيقي')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Text(provider.error ?? 'التنزيل يتم من المصادر الرسمية مع تحقق SHA-256 قبل التفعيل.'),
          const SizedBox(height: 16),
          if (provider.installing) LinearProgressIndicator(value: provider.installProgress),
          const SizedBox(height: 12),
          for (final distro in ZionRootfsDistro.values) Card(child: ListTile(
            title: Text(distro.name.toUpperCase()),
            subtitle: const Text('RootFS حقيقي — لا محاكاة'),
            trailing: FilledButton(onPressed: provider.installing ? null : () async { final r = await provider.install(distro.name); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.message))); }, child: const Text('تثبيت')),
          )),
        ]),
      )),
    );
  }
}