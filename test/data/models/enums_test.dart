import 'package:flutter_test/flutter_test.dart';
import 'package:dentlink/domain/enums/enums.dart';

void main() {
  group('UserTitle', () {
    group('dbValue and fromDbValue round-trip', () {
      for (final title in UserTitle.values) {
        test('correctly round-trips for ${title.name} (${title.dbValue})', () {
          // Arrange
          final dbValue = title.dbValue;

          // Act
          final result = UserTitle.fromDbValue(dbValue);

          // Assert
          expect(result, equals(title));
        });
      }
    });

    test('fromDbValue with null returns default unknown', () {
      // Arrange
      const String? value = null;

      // Act
      final result = UserTitle.fromDbValue(value);

      // Assert
      expect(result, equals(UserTitle.unknown));
    });

    test('fromDbValue with unknown value throws ArgumentError', () {
      // Arrange
      const invalidValue = 'unknown_title';

      // Act & Assert
      expect(
        () => UserTitle.fromDbValue(invalidValue),
        throwsA(isA<ArgumentError>()),
      );
    });

    group('tryFromDbValue', () {
      for (final title in UserTitle.values) {
        test('returns ${title.name} for ${title.dbValue}', () {
          // Arrange
          final dbValue = title.dbValue;

          // Act
          final result = UserTitle.tryFromDbValue(dbValue);

          // Assert
          expect(result, equals(title));
        });
      }

      test('returns null when input is null', () {
        // Arrange
        const String? value = null;

        // Act
        final result = UserTitle.tryFromDbValue(value);

        // Assert
        expect(result, isNull);
      });

      test('returns null when input is unknown string', () {
        // Arrange
        const invalidValue = 'non_existent_title';

        // Act
        final result = UserTitle.tryFromDbValue(invalidValue);

        // Assert
        expect(result, isNull);
      });
    });

    group('displayName', () {
      for (final title in UserTitle.values) {
        test('displayName is non-empty string for ${title.name}', () {
          // Act
          final displayName = title.displayName;

          // Assert
          expect(displayName, isNotEmpty);
        });
      }
    });
  });

  group('DentalBranch', () {
    group('dbValue and fromDbValue round-trip', () {
      for (final branch in DentalBranch.values) {
        test(
          'correctly round-trips for ${branch.name} (${branch.dbValue})',
          () {
            // Arrange
            final dbValue = branch.dbValue;

            // Act
            final result = DentalBranch.fromDbValue(dbValue);

            // Assert
            expect(result, equals(branch));
          },
        );
      }
    });

    test('fromDbValue with unknown value throws ArgumentError', () {
      // Arrange
      const invalidValue = 'unknown_branch';

      // Act & Assert
      expect(
        () => DentalBranch.fromDbValue(invalidValue),
        throwsA(isA<ArgumentError>()),
      );
    });

    group('tryFromDbValue', () {
      for (final branch in DentalBranch.values) {
        test('returns ${branch.name} for ${branch.dbValue}', () {
          // Arrange
          final dbValue = branch.dbValue;

          // Act
          final result = DentalBranch.tryFromDbValue(dbValue);

          // Assert
          expect(result, equals(branch));
        });
      }

      test('returns null when input is null', () {
        // Arrange
        const String? value = null;

        // Act
        final result = DentalBranch.tryFromDbValue(value);

        // Assert
        expect(result, isNull);
      });

      test('returns null when input is unknown string', () {
        // Arrange
        const invalidValue = 'non_existent_branch';

        // Act
        final result = DentalBranch.tryFromDbValue(invalidValue);

        // Assert
        expect(result, isNull);
      });
    });

    group('displayName', () {
      for (final branch in DentalBranch.values) {
        test('displayName is non-empty string for ${branch.name}', () {
          // Act
          final displayName = branch.displayName;

          // Assert
          expect(displayName, isNotEmpty);
        });
      }
    });
  });

  group('PostType', () {
    test('casePost.dbValue equals "case"', () {
      // Arrange & Act & Assert
      expect(PostType.casePost.dbValue, equals('case'));
    });

    test('question.dbValue equals "question"', () {
      // Arrange & Act & Assert
      expect(PostType.question.dbValue, equals('question'));
    });

    test('fromDbValue with "case" returns PostType.casePost', () {
      // Arrange
      const dbValue = 'case';

      // Act
      final result = PostType.fromDbValue(dbValue);

      // Assert
      expect(result, equals(PostType.casePost));
    });

    test('fromDbValue with "question" returns PostType.question', () {
      // Arrange
      const dbValue = 'question';

      // Act
      final result = PostType.fromDbValue(dbValue);

      // Assert
      expect(result, equals(PostType.question));
    });

    test('fromDbValue with unknown value throws ArgumentError', () {
      // Arrange
      const invalidValue = 'unknown_type';

      // Act & Assert
      expect(
        () => PostType.fromDbValue(invalidValue),
        throwsA(isA<ArgumentError>()),
      );
    });

    group('tryFromDbValue', () {
      test('returns PostType.casePost for "case"', () {
        // Arrange
        const dbValue = 'case';

        // Act
        final result = PostType.tryFromDbValue(dbValue);

        // Assert
        expect(result, equals(PostType.casePost));
      });

      test('returns PostType.question for "question"', () {
        // Arrange
        const dbValue = 'question';

        // Act
        final result = PostType.tryFromDbValue(dbValue);

        // Assert
        expect(result, equals(PostType.question));
      });

      test('returns null when input is null', () {
        // Arrange
        const String? value = null;

        // Act
        final result = PostType.tryFromDbValue(value);

        // Assert
        expect(result, isNull);
      });

      test('returns null when input is unknown string', () {
        // Arrange
        const invalidValue = 'invalid_post_type';

        // Act
        final result = PostType.tryFromDbValue(invalidValue);

        // Assert
        expect(result, isNull);
      });
    });

    test('profileTabs contains both casePost and question', () {
      // Act
      final tabs = PostType.profileTabs;

      // Assert
      expect(tabs, containsAll([PostType.casePost, PostType.question]));
      expect(tabs.length, equals(2));
    });
  });

  group('NotificationType', () {
    group('dbValue and fromDbValue round-trip', () {
      for (final type in NotificationType.values) {
        test('correctly round-trips for ${type.name} (${type.dbValue})', () {
          // Arrange
          final dbValue = type.dbValue;

          // Act
          final result = NotificationType.fromDbValue(dbValue);

          // Assert
          expect(result, equals(type));
        });
      }
    });

    test('fromDbValue with unknown value throws ArgumentError', () {
      // Arrange
      const invalidValue = 'unknown_notification';

      // Act & Assert
      expect(
        () => NotificationType.fromDbValue(invalidValue),
        throwsA(isA<ArgumentError>()),
      );
    });

    group('tryFromDbValue', () {
      for (final type in NotificationType.values) {
        test('returns ${type.name} for ${type.dbValue}', () {
          // Arrange
          final dbValue = type.dbValue;

          // Act
          final result = NotificationType.tryFromDbValue(dbValue);

          // Assert
          expect(result, equals(type));
        });
      }

      test('returns null when input is null', () {
        // Arrange
        const String? value = null;

        // Act
        final result = NotificationType.tryFromDbValue(value);

        // Assert
        expect(result, isNull);
      });

      test('returns null when input is unknown string', () {
        // Arrange
        const invalidValue = 'invalid_notification_type';

        // Act
        final result = NotificationType.tryFromDbValue(invalidValue);

        // Assert
        expect(result, isNull);
      });
    });
  });

  group('PostMenuAction', () {
    test('contains expected actions', () {
      // Act
      final actions = PostMenuAction.values;

      // Assert
      expect(
        actions,
        equals([
          PostMenuAction.edit,
          PostMenuAction.delete,
          PostMenuAction.report,
        ]),
      );
    });
  });
}
