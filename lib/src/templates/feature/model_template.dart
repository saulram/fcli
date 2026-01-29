import '../../config/fcli_config.dart';
import '../../utils/string_utils.dart';

/// Template for generating data/models/<feature>_model.dart
class ModelTemplate {
  ModelTemplate._();

  /// Generates a model class.
  ///
  /// [featureName] - The feature name (e.g., 'user', 'product')
  /// [config] - The fcli configuration
  /// [entityName] - Optional custom entity name, defaults to feature name
  /// [properties] - Optional list of properties as tuples (type, name, jsonKey)
  static String generate(
    String featureName,
    FcliConfig config, {
    String? entityName,
    List<(String type, String name, String? jsonKey)>? properties,
  }) {
    final name = entityName ?? featureName;

    if (config.useFreezed) {
      return _generateFreezedModel(name, config.projectName, featureName, properties);
    } else {
      return _generateManualModel(name, config.projectName, featureName, properties);
    }
  }

  static String _generateFreezedModel(
    String name,
    String projectName,
    String featureName,
    List<(String, String, String?)>? properties,
  ) {
    final pascalName = StringUtils.toPascalCase(name);
    final snakeName = StringUtils.toSnakeCase(name);
    final featureSnake = StringUtils.toSnakeCase(featureName);

    final props = properties ?? _defaultProperties(name);
    final propsCode = _generateFreezedProperties(props);
    final toEntityCode = _generateToEntity(pascalName, props);
    final fromEntityCode = _generateFromEntity(props);

    return '''
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:$projectName/features/$featureSnake/domain/entities/${snakeName}_entity.dart';

part '${snakeName}_model.freezed.dart';
part '${snakeName}_model.g.dart';

/// Data model for $pascalName with JSON serialization.
@freezed
sealed class ${pascalName}Model with _\$${pascalName}Model {
  const factory ${pascalName}Model({
$propsCode  }) = _${pascalName}Model;

  const ${pascalName}Model._();

  factory ${pascalName}Model.fromJson(Map<String, dynamic> json) =>
      _\$${pascalName}ModelFromJson(json);

  /// Converts this model to a domain entity.
  ${pascalName}Entity toEntity() => ${pascalName}Entity(
$toEntityCode
      );

  /// Creates a model from a domain entity.
  factory ${pascalName}Model.fromEntity(${pascalName}Entity entity) =>
      ${pascalName}Model(
$fromEntityCode
      );
}
''';
  }

  static String _generateManualModel(
    String name,
    String projectName,
    String featureName,
    List<(String, String, String?)>? properties,
  ) {
    final pascalName = StringUtils.toPascalCase(name);
    final snakeName = StringUtils.toSnakeCase(name);
    final featureSnake = StringUtils.toSnakeCase(featureName);

    final props = properties ?? _defaultProperties(name);
    final propsCode = _generateManualProperties(props);
    final constructorParams = _generateConstructorParams(props);
    final fromJsonCode = _generateFromJson(props);
    final toJsonCode = _generateToJson(props);
    final toEntityCode = _generateToEntity(pascalName, props);
    final fromEntityCode = _generateFromEntity(props);

    return '''
import 'package:$projectName/features/$featureSnake/domain/entities/${snakeName}_entity.dart';

/// Data model for $pascalName with JSON serialization.
class ${pascalName}Model {
  const ${pascalName}Model({
$constructorParams  });

$propsCode
  /// Creates a model from JSON.
  factory ${pascalName}Model.fromJson(Map<String, dynamic> json) =>
      ${pascalName}Model(
$fromJsonCode      );

  /// Converts this model to JSON.
  Map<String, dynamic> toJson() => {
$toJsonCode      };

  /// Converts this model to a domain entity.
  ${pascalName}Entity toEntity() => ${pascalName}Entity(
$toEntityCode
      );

  /// Creates a model from a domain entity.
  factory ${pascalName}Model.fromEntity(${pascalName}Entity entity) =>
      ${pascalName}Model(
$fromEntityCode
      );
}
''';
  }

  static List<(String, String, String?)> _defaultProperties(String name) => [
        ('String', 'id', null),
        ('String', 'name', null),
        ('DateTime', 'createdAt', 'created_at'),
        ('DateTime?', 'updatedAt', 'updated_at'),
      ];

  static String _generateFreezedProperties(
      List<(String, String, String?)> properties) {
    final buffer = StringBuffer();
    for (final (type, name, jsonKey) in properties) {
      final isRequired = !type.endsWith('?');
      if (jsonKey != null) {
        buffer.writeln("    @JsonKey(name: '$jsonKey')");
      }
      if (isRequired) {
        buffer.writeln('    required $type $name,');
      } else {
        buffer.writeln('    $type $name,');
      }
    }
    return buffer.toString();
  }

  static String _generateManualProperties(
      List<(String, String, String?)> properties) {
    final buffer = StringBuffer();
    for (final (type, name, _) in properties) {
      buffer.writeln('  final $type $name;');
    }
    return buffer.toString();
  }

  static String _generateConstructorParams(
      List<(String, String, String?)> properties) {
    final buffer = StringBuffer();
    for (final (type, name, _) in properties) {
      final isRequired = !type.endsWith('?');
      if (isRequired) {
        buffer.writeln('    required this.$name,');
      } else {
        buffer.writeln('    this.$name,');
      }
    }
    return buffer.toString();
  }

  static String _generateFromJson(List<(String, String, String?)> properties) {
    final buffer = StringBuffer();
    for (final (type, name, jsonKey) in properties) {
      final key = jsonKey ?? name;
      final camelName = StringUtils.toCamelCase(name);

      if (type.startsWith('DateTime')) {
        if (type.endsWith('?')) {
          buffer.writeln(
              "        $camelName: json['$key'] != null ? DateTime.parse(json['$key'] as String) : null,");
        } else {
          buffer.writeln(
              "        $camelName: DateTime.parse(json['$key'] as String),");
        }
      } else if (type.endsWith('?')) {
        buffer.writeln("        $camelName: json['$key'] as $type,");
      } else {
        buffer.writeln("        $camelName: json['$key'] as $type,");
      }
    }
    return buffer.toString();
  }

  static String _generateToJson(List<(String, String, String?)> properties) {
    final buffer = StringBuffer();
    for (final (type, name, jsonKey) in properties) {
      final key = jsonKey ?? name;
      final camelName = StringUtils.toCamelCase(name);

      if (type.startsWith('DateTime')) {
        if (type.endsWith('?')) {
          buffer.writeln("        '$key': $camelName?.toIso8601String(),");
        } else {
          buffer.writeln("        '$key': $camelName.toIso8601String(),");
        }
      } else {
        buffer.writeln("        '$key': $camelName,");
      }
    }
    return buffer.toString();
  }

  static String _generateToEntity(
    String pascalName,
    List<(String, String, String?)> properties,
  ) {
    final buffer = StringBuffer();
    for (final (_, name, _) in properties) {
      final camelName = StringUtils.toCamelCase(name);
      buffer.writeln('        $camelName: $camelName,');
    }
    return buffer.toString().trimRight();
  }

  static String _generateFromEntity(
    List<(String, String, String?)> properties,
  ) {
    final buffer = StringBuffer();
    for (final (_, name, _) in properties) {
      final camelName = StringUtils.toCamelCase(name);
      buffer.writeln('        $camelName: entity.$camelName,');
    }
    return buffer.toString().trimRight();
  }
}
