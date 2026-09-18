import 'package:flutter_test/flutter_test.dart';
import 'package:dentlink/core/utils/number_formatter.dart';

void main() {
  group('formatCount', () {
    group('numbers below 1,000', () {
      test('formats zero as "0"', () {
        // Arrange
        const count = 0;

        // Act
        final result = formatCount(count);

        // Assert
        expect(result, equals('0'));
      });

      test('formats single digit positive integer as plain string', () {
        // Arrange
        const count = 1;

        // Act
        final result = formatCount(count);

        // Assert
        expect(result, equals('1'));
      });

      test('formats 999 without suffix', () {
        // Arrange
        const count = 999;

        // Act
        final result = formatCount(count);

        // Assert
        expect(result, equals('999'));
      });

      test('formats negative numbers without suffix', () {
        // Arrange
        const count = -50;

        // Act
        final result = formatCount(count);

        // Assert
        expect(result, equals('-50'));
      });
    });

    group('numbers in thousands range (1,000 to 999,999)', () {
      test('formats 1000 as "1K" without decimal places', () {
        // Arrange
        const count = 1000;

        // Act
        final result = formatCount(count);

        // Assert
        expect(result, equals('1K'));
      });

      test('formats 1200 as "1.2K" with single decimal place', () {
        // Arrange
        const count = 1200;

        // Act
        final result = formatCount(count);

        // Assert
        expect(result, equals('1.2K'));
      });

      test('formats 1999 as "2.0K" rounding to one decimal place', () {
        // Arrange
        const count = 1999;

        // Act
        final result = formatCount(count);

        // Assert
        expect(result, equals('2.0K'));
      });

      test('formats 10000 as "10K" without decimal places', () {
        // Arrange
        const count = 10000;

        // Act
        final result = formatCount(count);

        // Assert
        expect(result, equals('10K'));
      });

      test('formats 999999 as "1000.0K" before reaching million threshold', () {
        // Arrange
        const count = 999999;

        // Act
        final result = formatCount(count);

        // Assert
        expect(result, equals('1000.0K'));
      });
    });

    group('numbers in millions range (1,000,000 and above)', () {
      test('formats 1000000 as "1M" without decimal places', () {
        // Arrange
        const count = 1000000;

        // Act
        final result = formatCount(count);

        // Assert
        expect(result, equals('1M'));
      });

      test('formats 1500000 as "1.5M" with single decimal place', () {
        // Arrange
        const count = 1500000;

        // Act
        final result = formatCount(count);

        // Assert
        expect(result, equals('1.5M'));
      });

      test('formats 2000000 as "2M" without decimal places', () {
        // Arrange
        const count = 2000000;

        // Act
        final result = formatCount(count);

        // Assert
        expect(result, equals('2M'));
      });
    });
  });
}
