import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentlink/main.dart';
import 'package:dentlink/data/providers/repository_providers.dart';

import 'mock_auth_for_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Faz 2.5 Comprehensive E2E UI Navigation Test', () {
    
    // Helper to safely go back
    Future<void> safeGoBack(WidgetTester tester) async {
      final defaultBack = find.byType(BackButton);
      final customBack = find.byIcon(Icons.arrow_back_ios_new_rounded);
      final customBack2 = find.byIcon(Icons.arrow_back_rounded);
      
      if (tester.any(defaultBack)) {
        await tester.tap(defaultBack.first);
      } else if (tester.any(customBack)) {
        await tester.tap(customBack.first);
      } else if (tester.any(customBack2)) {
        await tester.tap(customBack2.first);
      }
      await tester.pumpAndSettle();
    }

    testWidgets('Navigate through all screens', (tester) async {
      // 1. Build our app with the mocked AuthRepository
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(MockAuthForTest()),
          ],
          child: const MainApp(),
        ),
      );

      // Wait for initial routing (login -> feed)
      await tester.pumpAndSettle();

      // --- FEED & NOTIFICATIONS ---
      expect(find.byIcon(Icons.add_rounded), findsOneWidget); // Bottom nav +

      // Tap Notifications
      final notificationIcon = find.byIcon(Icons.notifications_none_rounded);
      if (tester.any(notificationIcon)) {
        await tester.tap(notificationIcon);
        await tester.pumpAndSettle();
        
        expect(find.text('Bildirimler'), findsWidgets);
        
        // Go back
        await safeGoBack(tester);
      }

      // Tap a post card on feed to go to detail screen
      final card = find.byType(Card);
      if (tester.any(card)) {
        await tester.tap(card.first);
        await tester.pumpAndSettle();
        
        // Go back
        await safeGoBack(tester);
      }

      // --- SEARCH ---
      // Navigate to Search
      await tester.tap(find.byIcon(Icons.explore_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Keşfet'), findsWidgets);
      
      // --- MESSAGES ---
      // Navigate to Messages
      await tester.tap(find.byIcon(Icons.chat_bubble_outline_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Mesajlar'), findsWidgets);
      
      // Tap a conversation
      final circleAvatar = find.byType(CircleAvatar);
      if (tester.any(circleAvatar)) {
        await tester.tap(circleAvatar.first);
        await tester.pumpAndSettle();
        
        // Go back
        await safeGoBack(tester);
      }

      // --- PROFILE ---
      // Navigate to Profile
      await tester.tap(find.byIcon(Icons.person_outline_rounded));
      await tester.pumpAndSettle();
      
      // Settings
      final settingsIcon = find.byIcon(Icons.settings_outlined);
      if (tester.any(settingsIcon)) {
        await tester.tap(settingsIcon);
        await tester.pumpAndSettle();
        
        // Go back
        await safeGoBack(tester);
      }

      // Edit Profile
      final editButton = find.text('Profili Düzenle');
      if (tester.any(editButton)) {
        await tester.tap(editButton);
        await tester.pumpAndSettle();
        
        // Go back
        await safeGoBack(tester);
      }

      // Followers
      final followersText = find.text('Takipçi');
      if (tester.any(followersText)) {
        await tester.tap(followersText.first);
        await tester.pumpAndSettle();
        
        // Go back
        await safeGoBack(tester);
      }

      // --- CREATE POST ---
      // Go back to feed
      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pumpAndSettle();
      
      // Tap +
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      
      // Tap Vaka Paylaş
      final vakaPaylas = find.text('Vaka Paylaş');
      if (tester.any(vakaPaylas)) {
        await tester.tap(vakaPaylas);
        await tester.pumpAndSettle();
        
        // Go back
        await safeGoBack(tester);
      }

      // Tap + again
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      
      // Tap Soru Sor
      final soruSor = find.text('Soru Sor');
      if (tester.any(soruSor)) {
        await tester.tap(soruSor);
        await tester.pumpAndSettle();
        
        // Go back
        await safeGoBack(tester);
      }
    });
  });
}
