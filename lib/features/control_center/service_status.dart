class ServiceStatus {
  final bool terminal;
  final bool userland;
  final bool ai;
  final bool p2p;
  const ServiceStatus({this.terminal=true,this.userland=true,this.ai=true,this.p2p=true});
  Map<String,bool> all()=>{'Terminal':terminal,'Userland':userland,'AI':ai,'P2P':p2p};
}
