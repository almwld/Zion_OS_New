import 'zion_pkg.dart';

class ZionPkgCli {
  const ZionPkgCli(this.pkg);
  final ZionPkg pkg;

  Future<String> run(List<String> args) async {
    if (args.isEmpty || args.first == 'help' || args.first == '--help') return usage;
    switch (args.first) {
      case 'list':
        final packages = await pkg.getInstalledPackages();
        if (packages.isEmpty) return 'No Zion packages installed.';
        return packages.map((p) => p.name + ' ' + p.version + ' [' + p.source + ']').join('\n');
      case 'status':
        if (args.length != 2) return 'Usage: zion-pkg status <package>';
        return (await pkg.getStatus(args[1])).name;
      case 'install':
        if (args.length != 2) return 'Usage: zion-pkg install <package|file.deb>';
        return _result(args[1].toLowerCase().endsWith('.deb')
            ? await pkg.installFromFile(args[1])
            : await pkg.installByName(args[1]));
      case 'install-from-file':
        if (args.length != 2) return 'Usage: zion-pkg install-from-file <file.deb>';
        return _result(await pkg.installFromFile(args[1]));
      case 'remove':
        if (args.length != 2) return 'Usage: zion-pkg remove <package>';
        return _result(await pkg.remove(args[1]));
      case 'update':
        if (args.length != 1) return 'Usage: zion-pkg update';
        return _result(await pkg.update());
      case 'upgrade':
        if (args.length != 1) return 'Usage: zion-pkg upgrade';
        return _result(await pkg.upgrade());
      default:
        return 'Unknown command: ' + args.first + '\n\n' + usage;
    }
  }

  String _result(PkgResult result) => result.success ? result.message ?? 'OK' : 'ERROR: ' + (result.error ?? 'operation failed');

  static const usage = '''zion-pkg — Zion Userland package manager

Commands:
  list
  status <package>
  install <package|file.deb>
  remove <package>
  update
  upgrade

Package names are resolved through the Zion Repository and verified with SHA-256.
Only Zion Userland apt/dpkg executables are used.''';
}
