import '../arsenal/arsenal_registry.dart';
import 'dart:io';
import 'zion_bootstrap.dart';
import 'zion_pkg.dart';
import 'zion_proot.dart';

class UserlandRegistry {
  const UserlandRegistry();
  static const toolIds = <String>{'packages.zion-bootstrap','packages.zion-pkg','runtime.zion-proot','api.zion-api'};
  List<ArsenalTool> tools() => const [
    ArsenalTool(id:'packages.zion-bootstrap',name:'Zion Bootstrap',category:ArsenalCategory.system,availability:ArsenalAvailability.notConfigured,command:'zion-bootstrap',reason:'A verified Zion Userland archive has not been installed.'),
    ArsenalTool(id:'packages.zion-pkg',name:'Zion Package Manager',category:ArsenalCategory.system,availability:ArsenalAvailability.notConfigured,command:'zion-pkg',reason:'Zion Userland package binaries are not installed.'),
    ArsenalTool(id:'runtime.zion-proot',name:'Zion PRoot Runtime',category:ArsenalCategory.system,availability:ArsenalAvailability.notConfigured,command:'proot',reason:'PRoot is not installed inside Zion Userland.'),
    ArsenalTool(id:'api.zion-api',name:'Zion API',category:ArsenalCategory.system,availability:ArsenalAvailability.notConfigured,command:'zion-api-battery',reason:'Zion API CLI scripts are installed with Zion Userland.'),
  ];
  Future<ArsenalAvailability> availability(String id) async {
    switch(id) {
      case 'packages.zion-bootstrap': return await ZionBootstrap.isInstalled() ? ArsenalAvailability.available : ArsenalAvailability.notConfigured;
      case 'packages.zion-pkg':
        final status=await ZionPkg().getStatus('zion-pkg');
        return switch(status){PackageStatus.installed || PackageStatus.available=>ArsenalAvailability.available,PackageStatus.system || PackageStatus.notInstalled=>ArsenalAvailability.notConfigured};
      case 'runtime.zion-proot':
        final status=await const ZionProot().inspect();
        return status.status==ProotStatus.available ? ArsenalAvailability.available : ArsenalAvailability.notConfigured;
      case 'api.zion-api':
        return await File(prefix+'/bin/zion-api-battery').exists() ? ArsenalAvailability.available : ArsenalAvailability.notConfigured;
      default:return ArsenalAvailability.unavailable;
    }
  }
  Future<List<ArsenalTool>> snapshot() async {
    final base=tools(); return [for(final tool in base) ArsenalTool(id:tool.id,name:tool.name,category:tool.category,availability:await availability(tool.id),command:tool.command,reason:tool.reason,requiresAuthorization:tool.requiresAuthorization)];
  }
}