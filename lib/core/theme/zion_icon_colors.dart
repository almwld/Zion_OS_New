import 'package:flutter/material.dart';
import 'zion_colors.dart';
class ZionIconColors {
  ZionIconColors._();
  static Color getColorFor(String name,{bool isDark=true}){
    switch(name.toLowerCase()){
      case 'terminal': return ZionColors.cyan;
      case 'browser': case 'file_manager': return ZionColors.cyan;
      case 'settings': return ZionColors.cyan;
      case 'wifi': case 'exploit': case 'ddos': case 'database': return ZionColors.cyan;
      case 'cracker': return ZionColors.cyan;
      case 'stealth': case 'crypto': case 'cleaner': return ZionColors.cyan;
      case 'firewall': return ZionColors.cyan;
      case 'vpn': return ZionColors.cyan;
      case 'network': case 'forensics': case 'calculator': return ZionColors.cyan;
      case 'notes': return ZionColors.cyan;
      case 'weather': case 'maps': case 'radio': case 'email': return ZionColors.cyan;
      default:return ZionColors.cyan;
    }
  }
  static Color getCategoryColor(String c,{bool isDark=true})=>switch(c.toUpperCase()){ 'ATTACK'=>ZionColors.neonIndigo,'DEFENSE'=>ZionColors.neonIndigo,'ANALYSIS'=>ZionColors.neonIndigo,'TOOLS'=>ZionColors.neonIndigo,_=>isDark?ZionColors.cyan:ZionColors.teal};
  static Color getStatusColor(String s)=>switch(s.toLowerCase()){ 'available'||'success'||'granted'=>ZionColors.neonIndigo,'permission_required'||'warning'=>ZionColors.neonIndigo,'unavailable'||'error'||'denied'=>ZionColors.neonIndigo,'not_configured'||'info'=>ZionColors.neonIndigo,_=>ZionColors.cyan};
}
