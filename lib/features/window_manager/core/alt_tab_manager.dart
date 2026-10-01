import '../core/window_manager.dart';
import '../models/window_id.dart';

/// Keeps one stable MRU snapshot while the user holds Alt and cycles with Tab.
class AltTabManager {
  AltTabManager(this.windowManager);
  final WindowManager windowManager;
  List<WindowId> _session = const [];
  int _index = 0;
  bool _active = false;

  bool get isActive => _active;
  WindowId? get selectedId => _active && _index < _session.length ? _session[_index] : null;
  List<WindowId> get sessionIds => List.unmodifiable(_session);

  void begin() {
    final windows = windowManager.visibleWindows.reversed.toList(growable: false);
    final active = windowManager.activeWindowId;
    final ids=<WindowId>[];
    if (active != null && windows.any((w)=>w.id==active)) ids.add(active);
    for(final window in windows) {
      if(window.id!=active) ids.add(window.id);
    }
    _session=ids;
    _index=0;
    _active=_session.length>1;
  }

  WindowId? cycle({bool reverse=false}) {
    if(!_active || _session.length<2) return selectedId;
    _index=(_index+(reverse?-1:1))%_session.length;
    if(_index<0) _index+=_session.length;
    windowManager.focusFromSnapshot(_session,_index);
    return _session[_index];
  }

  WindowId? end() {
    final id=selectedId;
    _session=const [];
    _index=0;
    _active=false;
    return id;
  }

  void cancel() {
    _session=const [];
    _index=0;
    _active=false;
  }
}
