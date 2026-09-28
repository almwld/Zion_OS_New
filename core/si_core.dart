class SiCore {
  bool _isActive = false;

  Future<void> activate() async {
    _isActive = true;
    print('🧠 SI Core activated');
  }

  Future<void> deactivate() async {
    _isActive = false;
    print('🧠 SI Core deactivated');
  }

  bool isActive() => _isActive;

  Future<void> process(String command) async {
    print('⚙️ Processing: $command');
  }
}
