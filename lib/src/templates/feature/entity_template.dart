import '../../utils/string_utils.dart';

/// Template for generating `domain/entities/{feature}_entity.dart`.
class EntityTemplate {
  EntityTemplate._();

  /// Generates an entity class.
  ///
  /// [featureName] - The feature name (e.g., 'user', 'product')
  /// [entityName] - Optional custom entity name, defaults to feature name
  /// [properties] - Optional list of properties as tuples (type, name)
  static String generate(
    String featureName, {
    String? entityName,
    List<(String type, String name)>? properties,
  }) {
    final name = entityName ?? featureName;
    final pascalName = StringUtils.toPascalCase(name);

    final props = properties ?? _defaultProperties(featureName);
    final propsCode = _generateProperties(props);
    final constructorParams = _generateConstructorParams(props);
    final equatableProps = _generateEquatableProps(props);

    return '''
import 'package:equatable/equatable.dart';

/// Entity representing a $pascalName in the domain layer.
class ${pascalName}Entity extends Equatable {
  const ${pascalName}Entity({
$constructorParams
  });

$propsCode

  @override
  List<Object?> get props => [$equatableProps];
}
''';
  }

  static List<(String, String)> _defaultProperties(String featureName) => [
        ('String', 'id'),
        ('String', 'name'),
        ('DateTime', 'createdAt'),
        ('DateTime?', 'updatedAt'),
      ];

  static String _generateProperties(List<(String, String)> properties) {
    final buffer = StringBuffer();
    for (final (type, name) in properties) {
      buffer.writeln('  final $type $name;');
    }
    return buffer.toString();
  }

  static String _generateConstructorParams(List<(String, String)> properties) {
    final buffer = StringBuffer();
    for (final (type, name) in properties) {
      final isRequired = !type.endsWith('?');
      if (isRequired) {
        buffer.writeln('    required this.$name,');
      } else {
        buffer.writeln('    this.$name,');
      }
    }
    return buffer.toString();
  }

  static String _generateEquatableProps(List<(String, String)> properties) =>
      properties.map((p) => p.$2).join(', ');
}
