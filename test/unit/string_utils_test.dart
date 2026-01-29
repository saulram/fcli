import 'package:flg/src/utils/string_utils.dart';
import 'package:test/test.dart';

void main() {
  group('StringUtils', () {
    group('toPascalCase', () {
      test('converts snake_case to PascalCase', () {
        expect(StringUtils.toPascalCase('user_profile'), equals('UserProfile'));
      });

      test('converts camelCase to PascalCase', () {
        expect(StringUtils.toPascalCase('userProfile'), equals('UserProfile'));
      });

      test('converts kebab-case to PascalCase', () {
        expect(StringUtils.toPascalCase('user-profile'), equals('UserProfile'));
      });

      test('converts single word to PascalCase', () {
        expect(StringUtils.toPascalCase('user'), equals('User'));
      });

      test('handles already PascalCase', () {
        expect(StringUtils.toPascalCase('UserProfile'), equals('UserProfile'));
      });
    });

    group('toCamelCase', () {
      test('converts snake_case to camelCase', () {
        expect(StringUtils.toCamelCase('user_profile'), equals('userProfile'));
      });

      test('converts PascalCase to camelCase', () {
        expect(StringUtils.toCamelCase('UserProfile'), equals('userProfile'));
      });

      test('converts kebab-case to camelCase', () {
        expect(StringUtils.toCamelCase('user-profile'), equals('userProfile'));
      });

      test('handles single word', () {
        expect(StringUtils.toCamelCase('user'), equals('user'));
      });
    });

    group('toSnakeCase', () {
      test('converts PascalCase to snake_case', () {
        expect(StringUtils.toSnakeCase('UserProfile'), equals('user_profile'));
      });

      test('converts camelCase to snake_case', () {
        expect(StringUtils.toSnakeCase('userProfile'), equals('user_profile'));
      });

      test('handles already snake_case', () {
        expect(StringUtils.toSnakeCase('user_profile'), equals('user_profile'));
      });
    });

    group('toKebabCase', () {
      test('converts PascalCase to kebab-case', () {
        expect(StringUtils.toKebabCase('UserProfile'), equals('user-profile'));
      });

      test('converts camelCase to kebab-case', () {
        expect(StringUtils.toKebabCase('userProfile'), equals('user-profile'));
      });

      test('converts snake_case to kebab-case', () {
        expect(StringUtils.toKebabCase('user_profile'), equals('user-profile'));
      });
    });

    group('toConstantCase', () {
      test('converts camelCase to CONSTANT_CASE', () {
        expect(
            StringUtils.toConstantCase('userProfile'), equals('USER_PROFILE'));
      });

      test('converts PascalCase to CONSTANT_CASE', () {
        expect(
            StringUtils.toConstantCase('UserProfile'), equals('USER_PROFILE'));
      });
    });

    group('toTitleCase', () {
      test('converts snake_case to Title Case', () {
        expect(StringUtils.toTitleCase('user_profile'), equals('User Profile'));
      });

      test('converts camelCase to Title Case', () {
        expect(StringUtils.toTitleCase('userProfile'), equals('User Profile'));
      });
    });

    group('toPlural', () {
      test('adds s for regular words', () {
        expect(StringUtils.toPlural('user'), equals('users'));
        expect(StringUtils.toPlural('product'), equals('products'));
      });

      test('adds es for words ending in s, x, z, ch, sh', () {
        expect(StringUtils.toPlural('bus'), equals('buses'));
        expect(StringUtils.toPlural('box'), equals('boxes'));
        expect(StringUtils.toPlural('buzz'), equals('buzzes'));
        expect(StringUtils.toPlural('watch'), equals('watches'));
        expect(StringUtils.toPlural('dish'), equals('dishes'));
      });

      test('handles words ending in y', () {
        expect(StringUtils.toPlural('city'), equals('cities'));
        expect(StringUtils.toPlural('category'), equals('categories'));
        // Words with vowel before y
        expect(StringUtils.toPlural('day'), equals('days'));
        expect(StringUtils.toPlural('key'), equals('keys'));
      });

      test('handles words ending in f or fe', () {
        expect(StringUtils.toPlural('leaf'), equals('leaves'));
        expect(StringUtils.toPlural('knife'), equals('knives'));
      });

      test('handles irregular plurals', () {
        expect(StringUtils.toPlural('child'), equals('children'));
        expect(StringUtils.toPlural('person'), equals('people'));
        expect(StringUtils.toPlural('man'), equals('men'));
        expect(StringUtils.toPlural('woman'), equals('women'));
      });

      test('preserves capitalization for irregular plurals', () {
        expect(StringUtils.toPlural('Child'), equals('Children'));
        expect(StringUtils.toPlural('Person'), equals('People'));
      });

      test('handles empty string', () {
        expect(StringUtils.toPlural(''), equals(''));
      });
    });

    group('capitalize', () {
      test('capitalizes first letter', () {
        expect(StringUtils.capitalize('hello'), equals('Hello'));
      });

      test('handles already capitalized', () {
        expect(StringUtils.capitalize('Hello'), equals('Hello'));
      });

      test('handles empty string', () {
        expect(StringUtils.capitalize(''), equals(''));
      });

      test('handles single character', () {
        expect(StringUtils.capitalize('h'), equals('H'));
      });
    });
  });
}
