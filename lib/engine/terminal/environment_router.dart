import 'command_registry.dart';
import 'environment_detector.dart';
import 'execution_context.dart';

class EnvironmentRouter {
  EnvironmentRouter({
    required this.detector,
    required this.registry,
    this.selection = EnvironmentSelection.auto,
  });

  final EnvironmentDetector detector;
  final CommandRegistry registry;
  final EnvironmentSelection selection;
  EnvironmentReport? _cachedReport;

  EnvironmentReport? get cachedReport => _cachedReport;

  Future<ExecutionContext> route(String command) async {
    final metadata = registry.lookup(command);
    if (metadata == null) {
      throw EnvironmentException(
        'الأمر غير معروف أو غير مسموح في CommandPolicy.',
      );
    }

    final report = _cachedReport ??= await detector.report();
    final preferred = metadata.preferredRuntime;

    if (selection == EnvironmentSelection.zionOnly) {
      return _zionContext(command, metadata, report);
    }
    if (selection == EnvironmentSelection.kaliOnly) {
      return _kaliContext(command, metadata, report);
    }
    if (selection == EnvironmentSelection.rootfsOnly) {
      throw EnvironmentException(
        'لم يتم ربط rootfs بمسار محلي موثوق في EnvironmentDetector.',
      );
    }

    if (preferred == 'zion' &&
        report.zionReady &&
        _hasRequiredTools(report, 'zion', metadata.requiredTools)) {
      return _context(command, metadata, ExecutionEnvironment.zion);
    }
    if (report.zionReady &&
        _hasRequiredTools(report, 'zion', metadata.requiredTools)) {
      return _context(command, metadata, ExecutionEnvironment.zion);
    }
    if (report.kaliReady == true &&
        _hasRequiredTools(report, 'kali', metadata.requiredTools)) {
      return _context(command, metadata, ExecutionEnvironment.kali);
    }

    throw EnvironmentException(
      'لا توجد بيئة مكتشفة تحتوي الأدوات المطلوبة: '
      '${metadata.requiredTools.join(', ')}',
    );
  }

  ExecutionContext _zionContext(
    String command,
    CommandMetadata metadata,
    EnvironmentReport report,
  ) {
    if (!report.zionReady ||
        !_hasRequiredTools(report, 'zion', metadata.requiredTools)) {
      throw EnvironmentException('بيئة Zion أو الأدوات المطلوبة غير متاحة.');
    }
    return _context(command, metadata, ExecutionEnvironment.zion);
  }

  ExecutionContext _kaliContext(
    String command,
    CommandMetadata metadata,
    EnvironmentReport report,
  ) {
    if (report.kaliReady != true ||
        !_hasRequiredTools(report, 'kali', metadata.requiredTools)) {
      throw EnvironmentException(
        'Kali غير مفحوصة أو غير متاحة؛ نفّذ فحص Kali الصريح أولاً.',
      );
    }
    return _context(command, metadata, ExecutionEnvironment.kali);
  }

  ExecutionContext _context(
    String command,
    CommandMetadata metadata,
    ExecutionEnvironment environment,
  ) =>
      ExecutionContext(
        command: command,
        environment: environment,
        timeout: metadata.timeout,
        requiresWrite: metadata.requiresWrite,
        requiresNetwork: metadata.requiresNetwork,
        requiredTools: metadata.requiredTools,
      );

  bool _hasRequiredTools(
    EnvironmentReport report,
    String runtime,
    Set<String> required,
  ) =>
      required.every((tool) => report.hasTool(runtime, tool));

  void invalidateCache() => _cachedReport = null;
}

class EnvironmentException implements Exception {
  const EnvironmentException(this.message);

  final String message;

  @override
  String toString() => 'EnvironmentException: $message';
}
