  void _clear() {
    final terminal = _selectedTab?.terminal;
    if (terminal == null) return;
    terminal.eraseDisplay();
    terminal.setCursor(0, 0);
  }

  Future<bool> _ensureAiLoaded() async {
    if (_ai.isLoaded) return true;
    final selected = await _ai.autoLoadBestModel(threads: 4);
    if (selected != null) {
      if (mounted) setState(() => _aiReady = true);
      return true;
    }
    if (mounted) setState(() => _aiReady = false);
    return false;
  }

  String? _extractCommand(String response) {
    final fenced = RegExp(
      r'```(?:bash|sh|shell)?\s*([\s\S]*?)```',
      caseSensitive: false,
    ).firstMatch(response);
    final value = (fenced?.group(1) ?? '').trim();
    if (value.isEmpty) return null;
    final lines = value
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('#'))
        .toList();
    return lines.isEmpty ? null : lines.join('\n');
  }

  bool _isSafeSuggestedCommand(String command) {
    final normalized = command.toLowerCase();
    const blocked = <String>[
      'rm -rf',
      'mkfs',
      'dd if=',
      'shutdown',
      'reboot',
      'poweroff',
      ':(){',
      'chmod -r 777',
    ];
    return !blocked.any(normalized.contains);
  }

  Future<void> _openAiAssistant() async {
    if (_aiLoading) return;
    setState(() => _aiLoading = true);
    try {
      final loaded = await _ensureAiLoaded();
      if (!loaded) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لم يتم العثور على نموذج GGUF محلي. افتح Offline AI لاستيراده أولاً.'),
            ),
          );
        }
        return;
      }
      if (!mounted) return;
      final prompt = TextEditingController();
      String? response;
      String? command;
      bool generating = false;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF101512),
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              Future<void> ask() async {
                final request = prompt.text.trim();
                if (request.isEmpty || generating) return;
                setSheetState(() {
                  generating = true;