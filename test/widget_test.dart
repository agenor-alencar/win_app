import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:win_app/main.dart';
import 'package:win_app/models/cart.dart';
import 'package:win_app/models/favorites.dart';

void main() {
  testWidgets('App inicia na tela de login', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => Cart()),
          ChangeNotifierProvider(create: (_) => Favorites()),
        ],
        child: const WinMarketplaceApp(initialRoute: '/login'),
      ),
    );

    expect(find.byType(WinMarketplaceApp), findsOneWidget);
  });
}
