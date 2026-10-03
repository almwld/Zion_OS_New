/// Source-of-truth catalogue imported from almwld/Zion_OS.
///
/// This file intentionally contains metadata only. It does not copy or expose
/// the legacy offensive implementations. Runtime execution remains owned by
/// Zion_OS_New's ArsenalRegistry/Executor/Userland boundary.
class ZionSourceArsenalModule {
  const ZionSourceArsenalModule({
    required this.id,
    required this.sourcePath,
    required this.className,
    required this.methodCount,
    required this.category,
    required this.status,
  });

  final String id;
  final String sourcePath;
  final String className;
  final int methodCount;
  final String category;
  final String status;
}

const List<ZionSourceArsenalModule> zionSourceArsenalModules = [
  ZionSourceArsenalModule(
    id: 'zion.advanced',
    sourcePath: 'lib/core/arsenal/zion_advanced.dart',
    className: 'ZionAdvanced',
    methodCount: 50,
    category: 'advanced',
    status: 'source_catalogued',
  ),
  ZionSourceArsenalModule(
    id: 'zion.crack',
    sourcePath: 'lib/core/arsenal/zion_crack.dart',
    className: 'ZionCrack',
    methodCount: 4,
    category: 'crypto',
    status: 'source_catalogued',
  ),
  ZionSourceArsenalModule(
    id: 'zion.evasion',
    sourcePath: 'lib/core/arsenal/zion_evasion.dart',
    className: 'ZionEvasion',
    methodCount: 97,
    category: 'evasion',
    status: 'source_catalogued',
  ),
  ZionSourceArsenalModule(
    id: 'zion.exploit',
    sourcePath: 'lib/core/arsenal/zion_exploit.dart',
    className: 'ZionExploit',
    methodCount: 100,
    category: 'exploitation',
    status: 'source_catalogued',
  ),
  ZionSourceArsenalModule(
    id: 'zion.forensics',
    sourcePath: 'lib/core/arsenal/zion_forensics.dart',
    className: 'ZionForensics',
    methodCount: 22,
    category: 'forensics',
    status: 'source_catalogued',
  ),
  ZionSourceArsenalModule(
    id: 'zion.mitm',
    sourcePath: 'lib/core/arsenal/zion_mitm.dart',
    className: 'ZionMITM',
    methodCount: 6,
    category: 'network',
    status: 'source_catalogued',
  ),
  ZionSourceArsenalModule(
    id: 'zion.net',
    sourcePath: 'lib/core/arsenal/zion_net.dart',
    className: 'ZionNet',
    methodCount: 8,
    category: 'network',
    status: 'source_catalogued',
  ),
  ZionSourceArsenalModule(
    id: 'zion.postexploit',
    sourcePath: 'lib/core/arsenal/zion_postexploit.dart',
    className: 'ZionPostExploit',
    methodCount: 62,
    category: 'post_exploitation',
    status: 'source_catalogued',
  ),
  ZionSourceArsenalModule(
    id: 'zion.web',
    sourcePath: 'lib/core/arsenal/zion_web.dart',
    className: 'ZionWeb',
    methodCount: 100,
    category: 'web',
    status: 'source_catalogued',
  ),
  ZionSourceArsenalModule(
    id: 'zion.wireless',
    sourcePath: 'lib/core/arsenal/zion_wireless.dart',
    className: 'ZionWireless',
    methodCount: 80,
    category: 'wireless',
    status: 'source_catalogued',
  ),
];

int get zionSourceArsenalMethodCount =>
    zionSourceArsenalModules.fold(0, (sum, module) => sum + module.methodCount);
