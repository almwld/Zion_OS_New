enum CtrlKey { c,d,z,l,esc,tab }
class CtrlKeys { int code(CtrlKey key)=>switch(key){CtrlKey.c=>3,CtrlKey.d=>4,CtrlKey.z=>26,CtrlKey.l=>12,CtrlKey.esc=>27,CtrlKey.tab=>9}; }