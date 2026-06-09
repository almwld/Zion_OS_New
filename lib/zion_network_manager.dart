import 'package:flutter/material.dart';
import 'dart:async';

class NetworkInterface {
  final String name;
  final String type; // wifi, ethernet, vpn, tor
  final String status; // connected, disconnected, connecting
  final String ipAddress;
  final String macAddress;
  final int signalStrength;
  final double txSpeed;
  final double rxSpeed;

  NetworkInterface({
    required this.name,
    required this.type,
    required this.status,
    required this.ipAddress,
    required this.macAddress,
    this.signalStrength = 100,
    this.txSpeed = 0,
    this.rxSpeed = 0,
  });
}

class ZionNetworkManager extends ChangeNotifier {
  final List<NetworkInterface> _interfaces = [
    NetworkInterface(name: 'wlan0', type: 'wifi', status: 'connected', ipAddress: '192.168.1.100', macAddress: 'AA:BB:CC:DD:EE:01', signalStrength: 85, txSpeed: 1.2, rxSpeed: 5.4),
    NetworkInterface(name: 'eth0', type: 'ethernet', status: 'disconnected', ipAddress: '-', macAddress: 'AA:BB:CC:DD:EE:02'),
    NetworkInterface(name: 'tun0', type: 'vpn', status: 'connected', ipAddress: '10.8.0.10', macAddress: '-', signalStrength: 100, txSpeed: 0.3, rxSpeed: 1.1),
    NetworkInterface(name: 'tor0', type: 'tor', status: 'connected', ipAddress: '127.0.0.1:9050', macAddress: '-', signalStrength: 100, txSpeed: 0.1, rxSpeed: 0.2),
  ];

  bool _vpnEnabled = true;
  bool _torEnabled = true;
  bool _firewallEnabled = true;
  bool _dnsOverHttps = true;

  List<NetworkInterface> get interfaces => _interfaces;
  bool get vpnEnabled => _vpnEnabled;
  bool get torEnabled => _torEnabled;
  bool get firewallEnabled => _firewallEnabled;
  bool get dnsOverHttps => _dnsOverHttps;

  void toggleVPN() { _vpnEnabled = !_vpnEnabled; notifyListeners(); }
  void toggleTor() { _torEnabled = !_torEnabled; notifyListeners(); }
  void toggleFirewall() { _firewallEnabled = !_firewallEnabled; notifyListeners(); }
  void toggleDNS() { _dnsOverHttps = !_dnsOverHttps; notifyListeners(); }

  void connectToWiFi(String ssid, String password) {
    final wifi = _interfaces.firstWhere((i) => i.name == 'wlan0');
    // محاكاة الاتصال
    notifyListeners();
  }
}
