# Example

final id = manager.open(
  title: 'Terminal',
  content: const TerminalScreen(),
  appKey: 'TERMINAL',
);
manager.focus(id);
manager.raise(id);
manager.close(id);