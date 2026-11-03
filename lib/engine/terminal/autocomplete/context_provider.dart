import 'dart:io';
import '../../../features/terminal/terminal_service.dart';

class ContextProvider {
  ContextProvider({this.terminal});
  final TerminalService? terminal;
  TerminalService? get _service=>terminal??TerminalService.activeInteractiveService;

  Future<String> getCurrentPath() async {
    try {
      if(_service?.isInteractiveRunning==true) {
        final r=await _service!.executeInInteractive('pwd',timeout:const Duration(seconds:5));
        if(r.exitCode==0&&r.stdout.trim().isNotEmpty)return r.stdout.trim();
      }
    } catch (_) {}
    try { return Directory.current.path; } catch (_) { return ''; }
  }

  Future<String?> getCurrentBranch() async {
    try {
      if(_service?.isInteractiveRunning!=true)return null;
      final r=await _service!.executeInInteractive('git branch --show-current',timeout:const Duration(seconds:5));
      return r.exitCode==0&&r.stdout.trim().isNotEmpty?r.stdout.trim():null;
    } catch (_) { return null; }
  }

  Future<List<String>> getBranches() async {
    try {
      if(_service?.isInteractiveRunning!=true)return const [];
      final r=await _service!.executeInInteractive('git branch --format="%(refname:short)"',timeout:const Duration(seconds:5));
      return r.exitCode==0?r.stdout.split('\n').map((e)=>e.trim()).where((e)=>e.isNotEmpty).toList():const [];
    } catch (_) { return const []; }
  }

  Future<List<String>> getRecentFiles({int limit=10}) async {
    try {
      final dir=Directory(await getCurrentPath());
      if(!await dir.exists())return const [];
      final files=await dir.list(followLinks:false).toList();
      files.sort((a,b)=>b.statSync().modified.compareTo(a.statSync().modified));
      return files.take(limit.clamp(1,50).toInt()).map((e)=>e.uri.pathSegments.isEmpty?e.path:e.uri.pathSegments.last).toList();
    } catch (_) { return const []; }
  }

  Future<bool> isFlutterProject() async=>File('${await getCurrentPath()}/pubspec.yaml').exists();
  Future<bool> isGitRepo() async=>Directory('${await getCurrentPath()}/.git').exists();
}
