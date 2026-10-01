import '../core/window_manager.dart';
import '../models/window_id.dart';
import '../models/window_snap.dart';
class SnapWindow {
  const SnapWindow(this.manager);
  final WindowManager manager;
  bool call(WindowId id, WindowSnap snap, {required double viewportWidth, required double viewportHeight, double topInset=0, double gap=0}) =>
      manager.snap(id, snap, viewportWidth: viewportWidth, viewportHeight: viewportHeight, topInset: topInset, gap: gap);
}