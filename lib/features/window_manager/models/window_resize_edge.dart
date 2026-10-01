enum WindowResizeEdge {
  left, right, top, bottom, topLeft, topRight, bottomLeft, bottomRight;
  bool get affectsLeft=>this==left||this==topLeft||this==bottomLeft;
  bool get affectsRight=>this==right||this==topRight||this==bottomRight;
  bool get affectsTop=>this==top||this==topLeft||this==topRight;
  bool get affectsBottom=>this==bottom||this==bottomLeft||this==bottomRight;
}