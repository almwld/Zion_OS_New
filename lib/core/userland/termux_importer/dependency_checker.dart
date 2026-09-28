import '../zion_repository.dart';
import 'package_reader.dart';
import 'path_converter.dart';

class DependencyCheck {
  const DependencyCheck({required this.ok, required this.missing});
  final bool ok;
  final List<String> missing;
}

class TermuxDependencyChecker {
  const TermuxDependencyChecker(this.repository);
  final ZionRepository repository;

  Future<DependencyCheck> check(TermuxPackage source, String targetArchitecture) async {
    if (source.depends.trim().isEmpty) return const DependencyCheck(ok: true, missing: <String>[]);
    final packages = await repository.listAll();
    final names = packages.where((p) => TermuxPathConverter.isCompatible(p.architecture, targetArchitecture)).map((p) => p.name).toSet();
    final missing = <String>[];
    for (final raw in source.depends.split(',')) {
      final dependency = raw.trim().split(RegExp(r'\s*[(<>=]')).first.trim();
      if (dependency.isEmpty) continue;
      if (!names.contains(dependency)) missing.add(dependency);
    }
    return DependencyCheck(ok: missing.isEmpty, missing: missing);
  }
}
