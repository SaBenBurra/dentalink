import 'package:flutter_test/flutter_test.dart';
import 'package:dentlink/core/utils/string_utils.dart';

void main() {
  group('generateUsername', () {
    test('generates username starting with normalized name and ending with numeric suffix', () {
      // Arrange
      const fullName = 'Ahmet Yilmaz';

      // Act
      final username = generateUsername(fullName);

      // Assert
      expect(username, startsWith('ahmet_yilmaz_'));
      final suffix = username.substring('ahmet_yilmaz_'.length);
      expect(int.tryParse(suffix), isNotNull);
    });

    test('generates username for single word name', () {
      // Arrange
      const fullName = 'Test';

      // Act
      final username = generateUsername(fullName);

      // Assert
      expect(username, startsWith('test_'));
    });

    test('defaults to user prefix when input is empty string', () {
      // Arrange
      const fullName = '';

      // Act
      final username = generateUsername(fullName);

      // Assert
      expect(username, startsWith('user_'));
    });

    test('defaults to user prefix when input contains only whitespace', () {
      // Arrange
      const fullName = '   ';

      // Act
      final username = generateUsername(fullName);

      // Assert
      expect(username, startsWith('user_'));
    });

    test('defaults to user prefix when all characters are special characters', () {
      // Arrange
      const fullName = '!!!@@@';

      // Act
      final username = generateUsername(fullName);

      // Assert
      expect(username, startsWith('user_'));
    });

    test('collapses multiple consecutive spaces between words into a single underscore', () {
      // Arrange
      const fullName = 'Ahmet    Yilmaz';

      // Act
      final username = generateUsername(fullName);

      // Assert
      expect(username, startsWith('ahmet_yilmaz_'));
    });

    test('matches pattern allowing only lowercase alphanumeric characters and underscores', () {
      // Arrange
      const fullName = 'Dr. Jane Doe-Smith 123!';

      // Act
      final username = generateUsername(fullName);

      // Assert
      expect(username, matches(RegExp(r'^[a-z0-9_]+$')));
    });

    test('strips non-ASCII Turkish characters before Turkish normalization map is applied', () {
      // Arrange
      const fullName = 'Çağla Öztürk';

      // Act
      final username = generateUsername(fullName);

      // Assert
      expect(username, startsWith('ala_ztrk_'));
    });
  });
}
