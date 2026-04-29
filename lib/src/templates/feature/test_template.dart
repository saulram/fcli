import '../../utils/string_utils.dart';

/// Templates for generated test scaffolds.
class TestTemplate {
  TestTemplate._();

  /// Generates a feature-level test scaffold.
  static String generateFeature(String featureName) {
    final titleName = StringUtils.toTitleCase(featureName);

    return '''
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('$titleName feature', () {
    test('has a generated test scaffold', () {
      expect(true, isTrue);
    });
  });
}
''';
  }

  /// Generates a screen test scaffold.
  static String generateScreen(String screenName, String featureName) {
    final titleScreen = StringUtils.toTitleCase(screenName);
    final titleFeature = StringUtils.toTitleCase(featureName);

    return '''
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('$titleFeature / $titleScreen screen', () {
    testWidgets('has a generated widget test scaffold', (tester) async {
      expect(true, isTrue);
    });
  });
}
''';
  }

  /// Generates a use case test scaffold.
  static String generateUseCase(String useCaseName, String featureName) {
    final titleUseCase = StringUtils.toTitleCase(useCaseName);
    final titleFeature = StringUtils.toTitleCase(featureName);

    return '''
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('$titleFeature / $titleUseCase use case', () {
    test('has a generated unit test scaffold', () {
      expect(true, isTrue);
    });
  });
}
''';
  }

  /// Generates a repository test scaffold.
  static String generateRepository(String repositoryName, String featureName) {
    final titleRepository = StringUtils.toTitleCase(repositoryName);
    final titleFeature = StringUtils.toTitleCase(featureName);

    return '''
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('$titleFeature / $titleRepository repository', () {
    test('has a generated repository test scaffold', () {
      expect(true, isTrue);
    });
  });
}
''';
  }
}
