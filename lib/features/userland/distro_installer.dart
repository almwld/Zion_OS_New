class DistroDefinition {
  final String name,arch;
  final bool requiresBootstrap;
  const DistroDefinition(this.name,{this.arch='aarch64',this.requiresBootstrap=true});
}
class DistroInstaller {
  static const supported=['Ubuntu','Arch','Kali','NixOS','Debian','Fedora','Alpine'];
  List<DistroDefinition> catalog(String arch)=>supported.map((name)=>DistroDefinition(name,arch:arch)).toList();
  bool supports(String name)=>supported.contains(name);
}
