import 'package:flutter/material.dart';
import 'zion_colors.dart';
class ZionIconColors {
  ZionIconColors._();
  static Color getColorFor(String name,{bool isDark=true}){
    switch(name.toLowerCase()){
      case 'terminal': return isDark?ZionColors.cyan:ZionColors.teal;
      case 'browser': case 'file_manager': return isDark?ZionColors.cyanLight:ZionColors.teal;
      case 'settings': return isDark?const Color(0xFF90A4AE):const Color(0xFF546E7A);
      case 'wifi': case 'exploit': case 'ddos': case 'database': return ZionColors.error;
      case 'cracker': return isDark?const Color(0xFFE91E63):const Color(0xFFAD1457);
      case 'stealth': case 'crypto': case 'cleaner': return isDark?ZionColors.success:const Color(0xFF00A04A);
      case 'firewall': return isDark?const Color(0xFF2BCBBA):const Color(0xFF00897B);
      case 'vpn': return isDark?const Color(0xFF45AAF2):const Color(0xFF1976D2);
      case 'network': case 'forensics': case 'calculator': return isDark?const Color(0xFF5352ED):const Color(0xFF3030A8);
      case 'notes': return isDark?const Color(0xFFFFC048):const Color(0xFFE68A00);
      case 'weather': case 'maps': case 'radio': case 'email': return isDark?const Color(0xFFFFB142):const Color(0xFFD97706);
      default:return isDark?ZionColors.cyan:ZionColors.teal;
    }
  }
  static Color getCategoryColor(String c,{bool isDark=true})=>switch(c.toUpperCase()){ 'ATTACK'=>ZionColors.attackRed,'DEFENSE'=>ZionColors.defenseGreen,'ANALYSIS'=>ZionColors.analysisBlue,'TOOLS'=>ZionColors.toolsOrange,_=>isDark?ZionColors.cyan:ZionColors.teal};
  static Color getStatusColor(String s)=>switch(s.toLowerCase()){ 'available'||'success'||'granted'=>ZionColors.success,'permission_required'||'warning'=>ZionColors.warning,'unavailable'||'error'||'denied'=>ZionColors.error,'not_configured'||'info'=>ZionColors.info,_=>ZionColors.cyan};
}
