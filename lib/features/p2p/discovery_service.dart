import 'dart:io';
class DiscoveryService { Future<List<NetworkInterface>> interfaces()=>NetworkInterface.list(); }