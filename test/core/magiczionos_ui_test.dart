import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:project_zion/core/magiczionos/magiczionos.dart';
import 'package:project_zion/core/magiczionos/widgets/strategy_selector.dart';

void main() {
  testWidgets('strategy selector renders explicit strategy labels', (tester) async {
    await tester.pumpWidget(
      MagiczionosProviderScope(child: const MagiczionosStrategySelector()),
    );
    expect(find.text('#magiczionos / Magisk'), findsOneWidget);
    expect(find.text('PRoot'), findsOneWidget);
    expect(find.text('Chroot'), findsOneWidget);
  });
}

class MagiczionosProviderScope extends StatelessWidget {
  const MagiczionosProviderScope({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MagiczionosProvider(),
      child: child,
    );
  }
}
