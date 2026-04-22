import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stanag_app/main.dart';
import 'package:stanag_app/models/user_state.dart';
import 'package:stanag_app/providers/auth_provider.dart';

void main() {
  testWidgets('App renders language test screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userStateProvider.overrideWith(
            (ref) => Stream.value(UserState.anonymous),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('English'), findsWidgets);
    expect(find.text('Polski'), findsOneWidget);
  });
}
