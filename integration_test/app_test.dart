import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'app_flow.dart';

/// Cihazda: flutter test integration_test/app_test.dart
/// Aynı akış headless olarak test/app_flow_test.dart'ta CI'da çalışır.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ana akış fake backend ile uçtan uca çalışır (TEST-2)', runAppFlow);
}
