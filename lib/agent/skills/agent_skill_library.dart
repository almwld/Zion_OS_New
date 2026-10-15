import 'dart:convert';

import 'package:flutter/services.dart';

/// Loads bundled Agent Skills as bounded prompt context. Skill files are
/// documentation only; they are never executed and cannot grant permissions.
class AgentSkillDefinition {
  final String name;
  final String asset;
  final String description;
  final List<String> keywords;

  const AgentSkillDefinition({
    required this.name,
    required this.asset,
    required this.description,
    required this.keywords,
  });
}

class AgentSkillLibrary {
  AgentSkillLibrary({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  Future<List<AgentSkillDefinition>>? _allDefinitionsFuture;

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
      .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static String _expandArabicQuery(String value) {
    final normalized = _normalize(value);
    const aliases = <String, String>{
      'برمجة': 'programming code development software engineering',
      'كود': 'code programming software development',
      'تطوير': 'development engineering implementation',
      'تصميم': 'design ui ux visual interface',
      'واجهة': 'ui ux frontend interface accessibility',
      'امان': 'security defensive audit vulnerability',
      'حماية': 'security defensive hardening',
      'اختبار': 'test testing quality assurance regression',
      'بيانات': 'data analytics database sql',
      'تحليل': 'analysis analytics audit debugging',
      'بحث': 'research search knowledge sources',
      'كتابة': 'writing documentation content',
      'مستند': 'document files office pdf',
      'ملفات': 'files documents filesystem',
      'نشر': 'deployment release ci cd',
      'اصدار': 'release versioning changelog',
      'شبكة': 'network infrastructure devops',
      'خادم': 'server backend api infrastructure',
      'سيرفر': 'server backend api infrastructure',
      'ذكاء': 'ai machine learning model llm',
      'نموذج': 'model ai machine learning inference',
      'مالي': 'finance accounting financial',
      'محاسبة': 'accounting finance',
      'تسويق': 'marketing seo growth',
      'طرفية': 'terminal shell linux command line',
      'لينكس': 'linux shell terminal devops',
      'سحابة': 'cloud infrastructure aws azure',
      'قاعدة': 'database sql schema',
      'وصول': 'accessibility a11y wcag',
      'متصفح': 'browser automation web',
      'صورة': 'image media design',
      'فيديو': 'video media editing',
      'صوت': 'audio speech voice',
    };
    final expansions = <String>[];
    for (final token in normalized.split(' ')) {
      final expansion = aliases[token];
      if (expansion != null) expansions.add(expansion);
    }
    return '$normalized ${expansions.join(' ')}';
  }

  static const List<AgentSkillDefinition> definitions = [
    AgentSkillDefinition(
      name: 'systematic-debugging',
      asset: 'assets/agent_skills/systematic-debugging.md',
      description: 'Evidence-first root-cause investigation and repair.',
      keywords: ['bug', 'debug', 'error', 'failure', 'crash', 'broken', 'diagnos', 'timeout', 'exception', 'build', 'خطأ', 'تعطل', 'فشل', 'تشخيص', 'مهلة', 'بناء',]
    ),
    AgentSkillDefinition(
      name: 'test-driven-development',
      asset: 'assets/agent_skills/test-driven-development.md',
      description: 'Test-first feature implementation and regression coverage.',
      keywords: ['test', 'regression', 'feature', 'implement', 'fix', 'refactor', 'assertion', 'اختبار', 'اختبارات', 'إصلاح', 'ميزة',]
    ),
    AgentSkillDefinition(
      name: 'verification-before-completion',
      asset: 'assets/agent_skills/verification-before-completion.md',
      description: 'Verify claims with fresh test and build evidence.',
      keywords: ['verify', 'verification', 'complete', 'finish', 'release', 'ci', 'apk', 'success', 'device', 'تحقق', 'اكتمال', 'إصدار', 'بناء', 'جهاز',]
    ),
    AgentSkillDefinition(
      name: 'writing-plans',
      asset: 'assets/agent_skills/writing-plans.md',
      description: 'Break complex requests into executable, verifiable steps.',
      keywords: ['plan', 'multi-step', 'architecture', 'design', 'task', 'workflow', 'roadmap', 'خطة', 'مهمة', 'سير العمل', 'تصميم',]
    ),
    AgentSkillDefinition(
      name: 'brainstorming',
      asset: 'assets/agent_skills/brainstorming.md',
      description: 'Compare designs and clarify constraints before large changes.',
      keywords: ['brainstorm', 'design', 'approach', 'options', 'architecture', 'new system'],
    ),
    AgentSkillDefinition(
      name: 'executing-plans',
      asset: 'assets/agent_skills/executing-plans.md',
      description: 'Execute incrementally with observed outputs and model-led recovery.',
      keywords: ['execute', 'execution', 'recover', 'retry', 'terminal', 'shell', 'runtime', 'kali', 'userland', 'rootfs', 'تنفيذ', 'استعادة', 'إعادة المحاولة', 'طرفية', 'كالي', 'لينكس',]
    ),
    AgentSkillDefinition(name: 'diagnosing-superpowers', asset: 'assets/agent_skills/diagnosing-superpowers.md', description: 'Diagnose skill discovery and invocation problems.', keywords: ['skill', 'skills', 'discovery', 'invoke', 'catalog', 'مهارة', 'مهارات', 'فهرس']),
    AgentSkillDefinition(name: 'dispatching-parallel-agents', asset: 'assets/agent_skills/dispatching-parallel-agents.md', description: 'Decompose independent work into parallelizable subtasks.', keywords: ['parallel', 'concurrent', 'independent tasks', 'subtasks']),
    AgentSkillDefinition(name: 'finishing-a-development-branch', asset: 'assets/agent_skills/finishing-a-development-branch.md', description: 'Verify branch state and prepare a clean delivery.', keywords: ['branch', 'pull request', 'merge', 'commit', 'finish', 'release']),
    AgentSkillDefinition(name: 'receiving-code-review', asset: 'assets/agent_skills/receiving-code-review.md', description: 'Evaluate review feedback against evidence and requirements.', keywords: ['review feedback', 'review comment', 'code review', 'critique']),
    AgentSkillDefinition(name: 'requesting-code-review', asset: 'assets/agent_skills/requesting-code-review.md', description: 'Check changes against correctness and quality criteria.', keywords: ['code review', 'review changes', 'quality', 'diff']),
    AgentSkillDefinition(name: 'subagent-driven-development', asset: 'assets/agent_skills/subagent-driven-development.md', description: 'Structure delegated work with explicit contracts and checks.', keywords: ['subagent', 'delegate', 'delegation', 'parallel implementation']),
    AgentSkillDefinition(name: 'using-git-worktrees', asset: 'assets/agent_skills/using-git-worktrees.md', description: 'Isolate concurrent repository work safely.', keywords: ['worktree', 'git worktree', 'parallel branch', 'isolate branch']),
    AgentSkillDefinition(name: 'using-superpowers', asset: 'assets/agent_skills/using-superpowers.md', description: 'Discover relevant workflow skills before work.', keywords: ['skill workflow', 'use skills', 'agent skill']),
    AgentSkillDefinition(name: 'writing-skills', asset: 'assets/agent_skills/writing-skills.md', description: 'Author and validate reusable agent skill documents.', keywords: ['write skill', 'create skill', 'skill authoring', 'skill testing']),
    AgentSkillDefinition(name: 'local-runtime-discovery', asset: 'assets/agent_skills/local-runtime-discovery.md', description: 'Discover and verify local Zion, Kali, and Linux rootfs environments.', keywords: ['kali', 'rootfs', 'local runtime', 'distro', 'linux environment', 'bash missing', 'كالي', 'روتفس', 'لينكس', 'توزيعة', 'بيئة محلية', 'باش']),
    AgentSkillDefinition(name: 'linux-package-inventory', asset: 'assets/agent_skills/linux-package-inventory.md', description: 'Inventory installed packages and tools without modifying the runtime.', keywords: ['installed packages', 'dpkg', 'apt list', 'package inventory', 'command -v', 'tools installed', 'حزم مثبتة', 'الحزم', 'الأدوات المثبتة']),
    AgentSkillDefinition(name: 'pty-evidence-debugging', asset: 'assets/agent_skills/pty-evidence-debugging.md', description: 'Diagnose terminal commands from real PTY output and exit codes.', keywords: ['pty', 'exit code', 'terminal timeout', 'shell error', 'command failed', 'hang', 'طرفية', 'رمز الخروج', 'مهلة الطرفية', 'خطأ أمر', 'تعليق']),
    AgentSkillDefinition(name: 'flutter-ci-repair', asset: 'assets/agent_skills/flutter-ci-repair.md', description: 'Repair Flutter and CI failures with commit-specific evidence.', keywords: ['github actions', 'ci failure', 'apk build', 'flutter analyze', 'workflow failed', 'build failed', 'إجراءات جيتهاب', 'فشل سي آي', 'بناء apk', 'تحليل فلاتر', 'فشل سير العمل']),
    AgentSkillDefinition(name: 'local-model-planning', asset: 'assets/agent_skills/local-model-planning.md', description: 'Keep the local GGUF model authoritative for plans and recovery.', keywords: ['gguf', 'model plan', 'invalid plan', 'local inference', 'token budget', 'planner', 'نموذج محلي', 'خطة النموذج', 'خطة غير صالحة', 'استدلال محلي']),
    AgentSkillDefinition(name: 'android-storage-inventory', asset: 'assets/agent_skills/android-storage-inventory.md', description: 'Discover local files and rootfs archives using bounded Android storage scans.', keywords: ['storage/emulated/0', 'local files', 'storage inventory', 'archive', 'rootfs archive', 'shared storage', 'التخزين', 'ملفات محلية', 'فهرسة التخزين', 'أرشيف', 'مساحة مشتركة']),
    AgentSkillDefinition(name: 'evidence-driven-recovery', asset: 'assets/agent_skills/evidence-driven-recovery.md', description: 'Run an observe-diagnose-repair-verify loop after tool failures.', keywords: ['recover', 'retry', 'repair step', 'failed step', 'recovery loop', 'diagnose and fix', 'استعادة', 'إعادة المحاولة', 'إصلاح خطوة', 'خطوة فاشلة', 'حل المشكلة']),
    AgentSkillDefinition(name: 'defensive-network-inventory', asset: 'assets/agent_skills/defensive-network-inventory.md', description: 'Identify installed security tools and plan low-impact authorized checks.', keywords: ['nmap', 'security tools', 'network inventory', 'authorized scan', 'defensive audit', 'إن ماب', 'أدوات أمنية', 'جرد الشبكة', 'فحص مصرح']),
    AgentSkillDefinition(name: 'git-safe-recovery', asset: 'assets/agent_skills/git-safe-recovery.md', description: 'Recover repository work without discarding user changes.', keywords: ['git recovery', 'lost changes', 'git conflict', 'reflog', 'restore branch', 'working tree', 'استعادة جيت', 'تغييرات مفقودة', 'تعارض جيت', 'سجل جيت', 'حالة المستودع']),
  ];

  /// Loads the static Zion skills plus the generated upstream catalog.
  /// Community skills are documentation-only and never grant tool permissions.
  Future<List<AgentSkillDefinition>> _allDefinitions() =>
      _allDefinitionsFuture ??= _loadAllDefinitions();

  Future<List<AgentSkillDefinition>> _loadAllDefinitions() async {
    final all = <AgentSkillDefinition>[...definitions];
    final knownNames = definitions.map((skill) => skill.name).toSet();
    try {
      final decoded = jsonDecode(
        await _bundle.loadString('assets/agent_skills/community_catalog.json'),
      );
      if (decoded is Map<String, dynamic> && decoded['entries'] is List) {
        for (final raw in decoded['entries'] as List) {
          if (raw is! Map) continue;
          final name = raw['name']?.toString().trim() ?? '';
          final description = raw['description']?.toString().trim() ?? '';
          final asset = raw['asset']?.toString().trim() ?? '';
          final keywordText = raw['keywords']?.toString() ?? '';
          if (name.isEmpty || description.isEmpty || asset.isEmpty || knownNames.contains(name)) {
            continue;
          }
          final keywords = keywordText
              .split(RegExp(r'\s+'))
              .map(_normalize)
              .where((keyword) => keyword.isNotEmpty)
              .toSet()
              .toList();
          if (keywords.isEmpty) keywords.add(_normalize(name));
          all.add(AgentSkillDefinition(
            name: name,
            asset: asset,
            description: description,
            keywords: keywords,
          ));
          knownNames.add(name);
        }
      }
    } catch (_) {
      // Keep Zion's built-in offline skills usable if an old install has no
      // generated community catalog yet.
    }
    return all;
  }

  /// Checks static Markdown assets and validates all generated catalog records.
  /// The sync workflow checks every community asset before it is committed.
  Future<List<String>> validateCatalog() async {
    final issues = <String>[];
    final names = <String>{};
    final assets = <String>{};
    for (final skill in definitions) {
      if (skill.name.trim().isEmpty || skill.description.trim().isEmpty || skill.keywords.isEmpty) {
        issues.add('Incomplete skill metadata: ${skill.name}');
      }
      if (!names.add(skill.name)) issues.add('Duplicate skill name: ${skill.name}');
      if (!assets.add(skill.asset)) issues.add('Duplicate skill asset: ${skill.asset}');
      try {
        final source = await _bundle.loadString(skill.asset);
        if (source.trim().isEmpty) issues.add('Empty skill asset: ${skill.asset}');
      } catch (_) {
        issues.add('Missing skill asset: ${skill.asset}');
      }
    }
    final all = await _allDefinitions();
    for (final skill in all.skip(definitions.length)) {
      if (!names.add(skill.name)) issues.add('Duplicate community skill name: ${skill.name}');
      if (!assets.add(skill.asset)) issues.add('Duplicate community skill asset: ${skill.asset}');
      if (skill.description.trim().isEmpty || skill.keywords.isEmpty) {
        issues.add('Incomplete community skill metadata: ${skill.name}');
      }
    }
    return issues;
  }

  List<AgentSkillDefinition> rank(
    String task, {
    Iterable<String> hints = const [],
  }) {
    final normalized = _normalize('$task ${hints.join(' ')}');
    final ranked = definitions.map((skill) {
      var score = normalized.contains(_normalize(skill.name)) ? 6 : 0;
      for (final keyword in skill.keywords) {
        final normalizedKeyword = _normalize(keyword.trim());
        if (normalizedKeyword.isNotEmpty && normalized.contains(normalizedKeyword)) {
          score += normalizedKeyword.contains(' ') ? 5 : 3;
        }
      }
      return (skill: skill, score: score);
    }).toList()
      ..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        if (byScore != 0) return byScore;
        return definitions.indexOf(a.skill).compareTo(definitions.indexOf(b.skill));
      });

    final relevant = ranked.where((entry) => entry.score > 0).map((entry) => entry.skill).toList();
    // Never inject unrelated skills for an unknown task. The planner should
    // receive no skill context rather than a misleading arbitrary fallback.
    return relevant;
  }

  /// Ranks every bundled skill, including the complete generated community index.
  /// Returns no unrelated fallback skills for an unmatched request.
  Future<List<AgentSkillDefinition>> rankAll(
    String task, {
    Iterable<String> hints = const [],
  }) async {
    final normalized = _expandArabicQuery('$task ${hints.join(' ')}');
    if (normalized.isEmpty) return const [];
    final candidates = await _allDefinitions();
    final ranked = candidates.map((skill) {
      var score = normalized.contains(_normalize(skill.name)) ? 6 : 0;
      for (final keyword in skill.keywords) {
        final normalizedKeyword = _normalize(keyword);
        if (normalizedKeyword.isNotEmpty && normalized.contains(normalizedKeyword)) {
          score += normalizedKeyword.contains(' ') ? 5 : 3;
        }
      }
      return (skill: skill, score: score);
    }).toList()
      ..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        if (byScore != 0) return byScore;
        return candidates.indexOf(a.skill).compareTo(candidates.indexOf(b.skill));
      });
    return ranked
        .where((entry) => entry.score > 0)
        .map((entry) => entry.skill)
        .toList(growable: false);
  }

  Future<String> contextFor(
    String task, {
    int maxSkills = 2,
    int maxCharsPerSkill = 900,
    int maxTotalChars = 2400,
    Iterable<String> hints = const [],
  }) async {
    if (task.trim().isEmpty || maxSkills < 1 || maxCharsPerSkill < 1 || maxTotalChars < 1) {
      return '';
    }

    final output = StringBuffer(
      'Relevant Agent Skills (guidance only; actual tool outputs and runtime policy are authoritative):\n',
    );
    var added = 0;
    for (final skill in (await rankAll(task, hints: hints)).take(maxSkills)) {
      String source;
      try {
        source = await _bundle.loadString(skill.asset);
      } catch (_) {
        continue;
      }
      source = source.replaceFirst(RegExp(r'^---\s*[\s\S]*?---\s*'), '').trim();
      if (source.isEmpty) continue;
      if (source.length > maxCharsPerSkill) {
        final cut = source.lastIndexOf('\n', maxCharsPerSkill);
        source = source.substring(0, cut > 0 ? cut : maxCharsPerSkill) +
            '\n[Skill excerpt shortened to fit the local model context.]';
      }
      final section = '\n### ${skill.name}: ${skill.description}\n$source\n';
      if (output.length + section.length > maxTotalChars) break;
      output.write(section);
      added++;
    }
    return added == 0 ? '' : output.toString();
  }
}
