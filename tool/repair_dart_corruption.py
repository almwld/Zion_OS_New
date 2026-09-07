from pathlib import Path
import re


def edit(path: str, fn) -> None:
    p = Path(path)
    if not p.exists():
        return
    source = p.read_text(encoding="utf-8")
    repaired = fn(source)
    if repaired != source:
        p.write_text(repaired, encoding="utf-8")
        print(f"repaired {path}")


def repair_stray_n(source: str) -> str:
    return re.sub(r"\);n(?=[ \t]*(?:buffer|\w))", ");\n", source)


def repair_web(source: str) -> str:
    return re.sub(r"(Future<bool> elasticsearchInjection\(String url\) async \{.*?body:\s*'[^']*')\s*;", r"\1,", source, count=1, flags=re.S)


def repair_viewmode(source: str) -> str:
    marker = "class AdvancedFileManager extends StatefulWidget {"
    if marker not in source:
        return source
    head, tail = source.split(marker, 1)
    if "enum ViewMode { grid, list }" not in head:
        head += "enum ViewMode { grid, list }\n\n"
    tail = tail.replace("\n  enum ViewMode { grid, list }\n", "\n", 1)
    return head + marker + tail


def repair_wifi_imports(source: str) -> str:
    imports = [
        "import 'zion_router_exploits.dart';",
        "import 'zion_ai_password_guesser.dart';",
        "import 'zion_guest_network_hack.dart';",
        "import 'zion_upnp_hack.dart';",
    ]
    for item in imports:
        source = source.replace("\n" + item, "")
    anchor = "import 'package:wifi_p2p/wifi_p2p.dart';"
    if anchor in source:
        prefix, suffix = source.split(anchor, 1)
        missing = [item for item in imports if item not in prefix]
        source = prefix + anchor + ("\n" + "\n".join(missing) if missing else "") + suffix
    return source


def repair_unified(source: str) -> str:
    source = re.sub(r"\n\s*case 'proot_status':.*\Z", "\n", source, count=1, flags=re.S)
    return source.replace("} catch (e) { return 'DNS failed: $e'; } }\n  }\n", "} catch (e) { return 'DNS failed: $e'; }\n  }\n", 1)


def repair_help(source: str) -> str:
    # Repair only the known corruption signatures. Preserve FAQ/search,
    # categories, tutorials, contact cards, and feedback functionality.
    source = source.replace(
        "return SingleChildScrollWidget('Phone', Icons.phone),child: Column(",
        "return SingleChildScrollView(child: Column(",
        1,
    )

    # The repaired ScrollView wraps the existing Column, so close both widgets.
    source = source.replace(
        "        ),\n      ],\n    );\n  }\n  \n  Widget _buildContactCard",
        "        ),\n      ],\n    ));\n  }\n  \n  Widget _buildContactCard",
        1,
    )

    # Remove only the duplicated/corrupted tail after _getIconData.
    duplicate_tail = "}\n}','Phone', Icons.phone),child: Column("
    if duplicate_tail in source:
        source = source.split(duplicate_tail, 1)[0].rstrip() + "\n"
    return source


def repair_settings(source: str) -> str:
    return re.sub(r"\n\}\n\n  void _resetAllSettings\(\) async \{.*\Z", "\n}\n", source, count=1, flags=re.S)


def repair_wifi_panel(source: str) -> str:
    marker = "\n  // إضافة أزرار للاستراتيجيات الجديدة"
    if marker in source:
        source = source.split(marker, 1)[0].rstrip() + "\n"
    return source


edit("lib/features/exploitation/exploit_screen.dart", repair_stray_n)
edit("lib/core/arsenal/zion_web.dart", repair_web)
edit("lib/core/arsenal/zion_postexploit.dart", lambda s: s.replace("'C$'", "'C\\$'"))
edit("lib/src/features/files/advanced_file_manager.dart", repair_viewmode)
edit("lib/src/core/arsenal/zion_wifi_real.dart", repair_wifi_imports)
edit("lib/core/services/unified_core_service.dart", repair_unified)
edit("lib/screens/help/advanced_help_center.dart", repair_help)
edit("lib/screens/settings/settings_screen.dart", repair_settings)
edit("lib/src/features/wifi/zion_wifi_panel_real.dart", repair_wifi_panel)
print("Dart corruption repair complete.")
