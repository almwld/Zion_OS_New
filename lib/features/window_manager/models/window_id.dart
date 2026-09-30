class WindowId {
  const WindowId(this.value);
  final String value;
  @override bool operator ==(Object other) => other is WindowId && other.value == value;
  @override int get hashCode => value.hashCode;
  @override String toString() => value;
}