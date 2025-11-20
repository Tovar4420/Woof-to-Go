import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_app/main.dart';

void main() {
  testWidgets('Woof to Go login screen test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
  await tester.pumpWidget(const WoofToGoApp());

    // Verify that the Woof to Go title is displayed
    expect(find.text('Woof to Go'), findsOneWidget);
    
    // Verify that login fields are present
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });
}