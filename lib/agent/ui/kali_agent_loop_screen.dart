import 'package:flutter/material.dart';
import '../../ai/llama_service.dart';
import '../../features/terminal/terminal_service.dart';

class KaliAgentLoopScreen extends StatefulWidget {
  final LlamaService ai;
  final TerminalService terminal;
  const KaliAgentLoopScreen({super.key, required this.ai, required this.terminal});
  @override State<KaliAgentLoopScreen> createState() => _KaliAgentLoopScreenState();
}

class _KaliAgentLoopScreenState extends State<KaliAgentLoopScreen> {
  final _target = TextEditingController();
  final _scroll = ScrollController();
  final _log = <String>[];
  bool _running = false, _modelReady = false;
  String _modelStatus = 'التحقق من النموذج المحلي…';
  int _iteration = 0;
  static const int _maxIterations = 6, _maxOutput = 3000;

  @override void initState() { super.initState(); _syncModel(); }

  Future<void> _syncModel() async {
    try {
      final ready = await widget.ai.nativeLoaded;
      if (mounted) setState(() {
        _modelReady = ready && widget.ai.isLoaded;
        _modelStatus = _modelReady ? 'النموذج المحلي جاهز' : 'حمّل GGUF من شاشة Zion Agent أولاً.';
      });
    } catch (_) {
      if (mounted) setState(() { _modelReady = widget.ai.isLoaded; _modelStatus = _modelReady ? 'النموذج المحلي جاهز' : 'تعذر التحقق من النموذج.'; });
    }
  }

  void _add(String s) {
    if (!mounted) return;
    setState(() => _log.add(s));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 160), curve: Curves.easeOut);
    });
  }

  String? _validTarget(String raw) {
    final v = raw.trim().toLowerCase().replaceFirst(RegExp(r'\.$'), '');
    final ip = RegExp(r'^(?:\d{1,3}\.){3}\d{1,3}$');
    final host = RegExp(r'^(?=.{1,253}$)[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?(?:\.[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)*$');
    if (v.isEmpty || v.length > 253 || (!ip.hasMatch(v) && !host.hasMatch(v))) return null;
    if (ip.hasMatch(v) && v.split('.').map(int.parse).any((n) => n > 255)) return null;
    return v;
  }

  Future<bool> _approve(String command, String reason) async {
    return await showDialog<bool>(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(
      title: const Text('موافقة قبل تشغيل أداة Kali'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(reason), const SizedBox(height: 10), SelectableText(command, textDirection: TextDirection.ltr),
        const SizedBox(height: 10), const Text('تأكد أن لديك إذناً صريحاً لفحص هذا الهدف.'),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('رفض')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('موافقة وتنفيذ')),
      ],
    )) ?? false;
  }

  Future<void> _startLoop() async {
    if (_running || !_modelReady) return;
    final target = _validTarget(_target.text);
    if (target == null) { _add('أدخل نطاقاً أو عنوان IPv4 صحيحاً واحداً.'); return; }
    setState(() { _running = true; _iteration = 0; _log.clear(); });
    _add('بدء الحلقة للهدف: ' + target);
    _add('كل أمر يتطلب موافقتك؛ الأدوات محدودة.');
    final history = <String>[];
    final seen = <String>{};
    try {
      for (var i = 1; i <= _maxIterations; i++) {
        if (!mounted) break;
        _iteration = i;
        final prompt = '''
أنت مساعد استطلاع دفاعي داخل Zion OS. الهدف الوحيد: $target
اختر أداة واحدة فقط من nmap, whois, dig, nslookup. ممنوع الاستغلال وكلمات المرور وbrute force وsqlmap وhydra وnikto وmasscan وأي أوامر shell مركبة.
whois/dig/nslookup يجب أن يستعملوا الهدف نفسه فقط.
nmap فقط مع -sT -Pn -n -sV و--top-ports من 1 إلى 100 أو -p مع 1-10 منافذ، والهدف آخر وسيط. لا تستخدم CIDR أو نطاقات أهداف.
إذا كفت النتائج أخرج ACTION: DONE. أخرج فقط:
ACTION: RUN أو THINK أو DONE
COMMAND: أمر واحد
REASONING: سبب مختصر
الهدف: $target
الخطوة: $i/$_maxIterations
السجل:
''' + history.join('\n').substring(0, 3500);
        final response = await widget.ai.generate(prompt, maxTokens: 180, temperature: 0.15);
        if (response.startsWith('ERROR:')) { _add('تعذر توليد الخطوة: ' + response); break; }
        final action = RegExp(r'ACTION\s*:\s*(RUN|THINK|DONE)', caseSensitive: false).firstMatch(response)?.group(1)?.toUpperCase();
        final reason = RegExp(r'REASONING\s*:\s*([^\r\n]+)', caseSensitive: false).firstMatch(response)?.group(1)?.trim() ?? 'لا يوجد تفسير.';
        _add('تحليل: ' + reason);
        history.add('الخطوة ' + i.toString() + ': ' + reason);
        if (action == 'DONE') { _add('قرر Qwen أن المهمة اكتملت.'); break; }
        if (action == 'THINK') { _add('إعادة تقييم دون تنفيذ.'); continue; }
        if (action != 'RUN') { _add('رد غير مفهوم؛ أوقفت الحلقة.'); break; }
        final command = RegExp(r'^\s*COMMAND\s*:\s*([^\r\n]+)', multiLine: true, caseSensitive: false).firstMatch(response)?.group(1)?.trim() ?? '';
        final parsed = _parseCommand(command, target);
        if (parsed == null) { _add('رفضت بوابة الأمان الأمر: ' + command); history.add('أمر مرفوض من بوابة الأمان.'); continue; }
        if (!seen.add(command)) { _add('تكرار الأمر؛ إيقاف الحلقة.'); break; }
        if (!await _approve(command, reason)) { _add('رفض المستخدم الأمر؛ توقفت الحلقة.'); break; }
        final result = await _executeKali(parsed.$1, parsed.$2);
        final out = result.output.length > _maxOutput ? result.output.substring(0, _maxOutput) + '\n… اقتطعت المخرجات.' : result.output;
        _add((result.ok ? 'نتيجة: ' : 'تحذير: ') + command + '\n' + out);
        history.add('COMMAND: ' + command + '\nEXIT: ' + result.code.toString() + '\nOUTPUT: ' + out.substring(0, out.length > 800 ? 800 : out.length));
        if (result.code == 127) { _add('تحقق من تثبيت الأداة وتجهيز Kali Userland.'); break; }
      }
      if (_iteration >= _maxIterations) _add('وصلنا إلى الحد الأقصى (' + _maxIterations.toString() + ').');
    } catch (e) { _add('خطأ أثناء الحلقة: ' + e.toString()); }
    finally { if (mounted) setState(() => _running = false); }
  }

  (String, List<String>)? _parseCommand(String command, String target) {
    if (command.isEmpty || command.length > 240 || RegExp(r'[;&|<>$()\r\n]').hasMatch(command)) return null;
    final p = command.split(RegExp(r'\s+'));
    final tool = p.first, args = p.skip(1).toList();
    if (args.any((a) => a.contains('/') || a.contains('*') || a.startsWith('-o') || a.startsWith('--script'))) return null;
    if (tool == 'whois' || tool == 'dig' || tool == 'nslookup') {
      if (args.length != 1 || args.single.toLowerCase().replaceFirst(RegExp(r'\.$'), '') != target) return null;
      return (tool, args);
    }
    if (tool != 'nmap') return null;
    final out = <String>[];
    const flags = {'-sT', '-Pn', '-n', '-sV'};
    var i = 0, hasTarget = false, hasPorts = false;
    while (i < args.length) {
      final a = args[i];
      if (a.toLowerCase().replaceFirst(RegExp(r'\.$'), '') == target) {
        if (hasTarget || i != args.length - 1) return null;
        hasTarget = true; out.add(target); i++; continue;
      }
      if (flags.contains(a)) { out.add(a); i++; continue; }
      if ((a == '--top-ports' || a == '-p' || a == '--max-retries') && i + 1 < args.length) {
        final value = args[i + 1];
        if (a == '--top-ports') {
          final n = int.tryParse(value); if (n == null || n < 1 || n > 100) return null;
          hasPorts = true;
        } else if (a == '-p') {
          if (!RegExp(r'^\d{1,5}(?:,\d{1,5}){0,9}$').hasMatch(value) || value.split(',').any((s) => int.parse(s) < 1 || int.parse(s) > 65535)) return null;
          hasPorts = true;
        } else {
          final n = int.tryParse(value); if (n == null || n < 0 || n > 2) return null;
        }
        out.addAll([a, value]); i += 2; continue;
      }
      return null;
    }
    if (!hasTarget) return null;
    if (!hasPorts) out.insertAll(0, ['--top-ports', '20']);
    return (tool, out);
  }

  Future<_KaliResult> _executeKali(String tool, List<String> args) async {
    // Do not launch PRoot with Process.start here: that bypasses Zion's
    // native PTY, packaged PROOT_LOADER, and Android linker path. Reuse the
    // shared TerminalService so Kali commands get the same runtime setup and
    // exit-marker capture as the main terminal and Super Agent.
    final probe = await widget.terminal.executeInInteractive(
      'command -v $tool',
      runtime: 'kali',
      timeout: const Duration(seconds: 20),
    );
    if (!probe.succeeded || probe.stdout.trim().isEmpty) {
      final detail = probe.formatted.isEmpty ? 'لم يتم العثور على الأداة داخل Kali.' : probe.formatted;
      return _KaliResult(false, probe.exitCode == 0 ? 127 : probe.exitCode, detail);
    }

    // _parseCommand only permits fixed tool names, validated flags/ports, and
    // the single validated target, so this token join cannot introduce shell
    // metacharacters or a second command.
    final command = <String>[tool, ...args].join(' ');
    final result = await widget.terminal.executeInInteractive(
      command,
      runtime: 'kali',
      timeout: const Duration(minutes: 5),
    );
    final output = result.formatted;
    return _KaliResult(
      result.succeeded,
      result.exitCode,
      output.isEmpty ? 'لا توجد مخرجات (exit code ${result.exitCode}).' : output,
    );
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Zion Agent Loop · Kali'), actions: [
      IconButton(onPressed: _running ? null : _syncModel, icon: const Icon(Icons.refresh), tooltip: 'فحص النموذج'),
    ]),
    body: Column(children: [
      Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(_modelReady ? Icons.memory : Icons.warning_amber, color: _modelReady ? Colors.green : Colors.orange), const SizedBox(width: 8), Expanded(child: Text(_modelStatus))]),
        const SizedBox(height: 8),
        TextField(controller: _target, enabled: !_running, autocorrect: false, textDirection: TextDirection.ltr,
          decoration: const InputDecoration(labelText: 'الهدف المصرح به (نطاق أو IPv4)', hintText: '127.0.0.1 أو example.org', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        const Text('Qwen يخطط ← موافقتك ← أداة Kali ← تحليل النتيجة ← الخطوة التالية. لا يوجد تنفيذ تلقائي.', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: FilledButton.icon(
          onPressed: !_running && _modelReady ? _startLoop : null,
          icon: _running ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.loop),
          label: Text(_running ? 'الحلقة تعمل…' : 'بدء Agent Loop'))),
      ])),
      const Divider(height: 1),
      Expanded(child: ListView.builder(controller: _scroll, padding: const EdgeInsets.all(12), itemCount: _log.length,
        itemBuilder: (context, i) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: SelectableText(_log[i])))),
    ]),
  );

  @override void dispose() { _target.dispose(); _scroll.dispose(); super.dispose(); }
}

class _KaliResult {
  final bool ok; final int code; final String output;
  const _KaliResult(this.ok, this.code, this.output);
}
