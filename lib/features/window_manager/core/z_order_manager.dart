import '../models/app_window.dart';
class WindowZOrderManager {
  int _counter=0;
  int raise(AppWindow w){w.zIndex=++_counter;return w.zIndex;}
  List<AppWindow> sort(Iterable<AppWindow> windows){final r=windows.toList();r.sort((a,b)=>a.zIndex.compareTo(b.zIndex));return r;}
  void seed(Iterable<AppWindow> windows){for(final w in windows){if(w.zIndex>_counter)_counter=w.zIndex;}}
  void reset()=>_counter=0;
}