import '../../config/fcli_config.dart';
import '../../utils/string_utils.dart';

/// Template for generating `presentation/providers/{feature}_notifier.dart`.
class NotifierTemplate {
  NotifierTemplate._();

  /// Generates a state management provider/notifier.
  ///
  /// [featureName] - The feature name (e.g., 'user', 'product')
  /// [config] - The fcli configuration
  /// [entityName] - Optional custom entity name, defaults to feature name
  static String generate(
    String featureName,
    FcliConfig config, {
    String? entityName,
  }) {
    final name = entityName ?? featureName;
    final projectName = config.projectName;
    final featureSnake = StringUtils.toSnakeCase(featureName);

    if (config.usesRiverpod) {
      return _generateRiverpodNotifier(name, projectName, featureSnake);
    } else if (config.usesBloc) {
      return _generateBloc(name, projectName, featureSnake);
    } else {
      return _generateChangeNotifier(name, projectName, featureSnake);
    }
  }

  static String _generateRiverpodNotifier(
    String name,
    String projectName,
    String featureSnake,
  ) {
    final pascalName = StringUtils.toPascalCase(name);
    final snakeName = StringUtils.toSnakeCase(name);
    final camelName = StringUtils.toCamelCase(name);
    final pluralCamel = StringUtils.toPlural(camelName);

    return '''
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:$projectName/features/$featureSnake/domain/entities/${snakeName}_entity.dart';
import 'package:$projectName/features/$featureSnake/domain/repositories/${snakeName}_repository.dart';
import 'package:$projectName/features/$featureSnake/presentation/providers/${snakeName}_state.dart';

part '${snakeName}_provider.g.dart';

/// Provider for managing $pascalName state.
@riverpod
class $pascalName extends _\$$pascalName {
  ${pascalName}Repository? _repository;

  @override
  ${pascalName}State build() {
    return const ${pascalName}State();
  }

  /// Sets the repository. Call this before using other methods.
  void setRepository(${pascalName}Repository repository) {
    _repository = repository;
  }

  /// Loads all $pluralCamel.
  Future<void> loadAll() async {
    if (_repository == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _repository!.getAll();

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      ($pluralCamel) => state = state.copyWith(
        isLoading: false,
        $pluralCamel: $pluralCamel,
      ),
    );
  }

  /// Loads a single $camelName by ID.
  Future<void> loadById(String id) async {
    if (_repository == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _repository!.getById(id);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      ($camelName) => state = state.copyWith(
        isLoading: false,
        selected$pascalName: $camelName,
      ),
    );
  }

  /// Creates a new $camelName.
  Future<void> create(${pascalName}Entity entity) async {
    if (_repository == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _repository!.create(entity);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      ($camelName) {
        final updated = [...state.$pluralCamel, $camelName];
        state = state.copyWith(
          isLoading: false,
          $pluralCamel: updated,
        );
      },
    );
  }

  /// Updates an existing $camelName.
  Future<void> update(${pascalName}Entity entity) async {
    if (_repository == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _repository!.update(entity);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      ($camelName) {
        final updated = state.$pluralCamel.map((e) {
          return e.id == $camelName.id ? $camelName : e;
        }).toList();
        state = state.copyWith(
          isLoading: false,
          $pluralCamel: updated,
        );
      },
    );
  }

  /// Deletes a $camelName by ID.
  Future<void> delete(String id) async {
    if (_repository == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _repository!.delete(id);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (_) {
        final updated = state.$pluralCamel.where((e) => e.id != id).toList();
        state = state.copyWith(
          isLoading: false,
          $pluralCamel: updated,
        );
      },
    );
  }

  /// Clears any error state.
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Selects a $camelName.
  void select(${pascalName}Entity? $camelName) {
    state = state.copyWith(selected$pascalName: $camelName);
  }
}
''';
  }

  static String _generateBloc(
    String name,
    String projectName,
    String featureSnake,
  ) {
    final pascalName = StringUtils.toPascalCase(name);
    final snakeName = StringUtils.toSnakeCase(name);
    final camelName = StringUtils.toCamelCase(name);

    return '''
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:$projectName/features/$featureSnake/domain/entities/${snakeName}_entity.dart';
import 'package:$projectName/features/$featureSnake/domain/repositories/${snakeName}_repository.dart';

part '${snakeName}_event.dart';
part '${snakeName}_state.dart';

/// BLoC for managing $pascalName state.
class ${pascalName}Bloc extends Bloc<${pascalName}Event, ${pascalName}State> {
  ${pascalName}Bloc({
    required ${pascalName}Repository repository,
  })  : _repository = repository,
        super(const ${pascalName}Initial()) {
    on<Load${pascalName}s>(_onLoadAll);
    on<Load$pascalName>(_onLoadById);
    on<Create$pascalName>(_onCreate);
    on<Update$pascalName>(_onUpdate);
    on<Delete$pascalName>(_onDelete);
  }

  final ${pascalName}Repository _repository;

  Future<void> _onLoadAll(
    Load${pascalName}s event,
    Emitter<${pascalName}State> emit,
  ) async {
    emit(const ${pascalName}Loading());

    final result = await _repository.getAll();

    result.fold(
      (failure) => emit(${pascalName}Error(failure.message)),
      (${camelName}s) => emit(${pascalName}Loaded(${camelName}s)),
    );
  }

  Future<void> _onLoadById(
    Load$pascalName event,
    Emitter<${pascalName}State> emit,
  ) async {
    emit(const ${pascalName}Loading());

    final result = await _repository.getById(event.id);

    result.fold(
      (failure) => emit(${pascalName}Error(failure.message)),
      ($camelName) => emit(${pascalName}DetailLoaded($camelName)),
    );
  }

  Future<void> _onCreate(
    Create$pascalName event,
    Emitter<${pascalName}State> emit,
  ) async {
    emit(const ${pascalName}Loading());

    final result = await _repository.create(event.entity);

    result.fold(
      (failure) => emit(${pascalName}Error(failure.message)),
      ($camelName) => emit(${pascalName}Created($camelName)),
    );
  }

  Future<void> _onUpdate(
    Update$pascalName event,
    Emitter<${pascalName}State> emit,
  ) async {
    emit(const ${pascalName}Loading());

    final result = await _repository.update(event.entity);

    result.fold(
      (failure) => emit(${pascalName}Error(failure.message)),
      ($camelName) => emit(${pascalName}Updated($camelName)),
    );
  }

  Future<void> _onDelete(
    Delete$pascalName event,
    Emitter<${pascalName}State> emit,
  ) async {
    emit(const ${pascalName}Loading());

    final result = await _repository.delete(event.id);

    result.fold(
      (failure) => emit(${pascalName}Error(failure.message)),
      (_) => emit(${pascalName}Deleted(event.id)),
    );
  }
}
''';
  }

  static String _generateChangeNotifier(
    String name,
    String projectName,
    String featureSnake,
  ) {
    final pascalName = StringUtils.toPascalCase(name);
    final snakeName = StringUtils.toSnakeCase(name);
    final camelName = StringUtils.toCamelCase(name);
    final pluralCamel = StringUtils.toPlural(camelName);

    return '''
import 'package:flutter/foundation.dart';

import 'package:$projectName/features/$featureSnake/domain/entities/${snakeName}_entity.dart';
import 'package:$projectName/features/$featureSnake/domain/repositories/${snakeName}_repository.dart';

/// ChangeNotifier for managing $pascalName state.
class ${pascalName}Provider extends ChangeNotifier {
  ${pascalName}Provider({
    required ${pascalName}Repository repository,
  }) : _repository = repository;

  final ${pascalName}Repository _repository;

  List<${pascalName}Entity> _$pluralCamel = [];
  List<${pascalName}Entity> get $pluralCamel => _$pluralCamel;

  ${pascalName}Entity? _selected$pascalName;
  ${pascalName}Entity? get selected$pascalName => _selected$pascalName;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Loads all $pluralCamel.
  Future<void> loadAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.getAll();

    result.fold(
      (failure) {
        _errorMessage = failure.message;
      },
      ($pluralCamel) {
        _$pluralCamel = $pluralCamel;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  /// Loads a single $camelName by ID.
  Future<void> loadById(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.getById(id);

    result.fold(
      (failure) {
        _errorMessage = failure.message;
      },
      ($camelName) {
        _selected$pascalName = $camelName;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  /// Creates a new $camelName.
  Future<bool> create(${pascalName}Entity entity) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.create(entity);

    var success = false;
    result.fold(
      (failure) {
        _errorMessage = failure.message;
      },
      ($camelName) {
        _$pluralCamel = [..._$pluralCamel, $camelName];
        success = true;
      },
    );

    _isLoading = false;
    notifyListeners();
    return success;
  }

  /// Updates an existing $camelName.
  Future<bool> update(${pascalName}Entity entity) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.update(entity);

    var success = false;
    result.fold(
      (failure) {
        _errorMessage = failure.message;
      },
      ($camelName) {
        _$pluralCamel = _$pluralCamel.map((e) {
          return e.id == $camelName.id ? $camelName : e;
        }).toList();
        success = true;
      },
    );

    _isLoading = false;
    notifyListeners();
    return success;
  }

  /// Deletes a $camelName by ID.
  Future<bool> delete(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.delete(id);

    var success = false;
    result.fold(
      (failure) {
        _errorMessage = failure.message;
      },
      (_) {
        _$pluralCamel = _$pluralCamel.where((e) => e.id != id).toList();
        success = true;
      },
    );

    _isLoading = false;
    notifyListeners();
    return success;
  }

  /// Selects a $camelName.
  void select(${pascalName}Entity? $camelName) {
    _selected$pascalName = $camelName;
    notifyListeners();
  }

  /// Clears any error state.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
''';
  }

  /// Generates the state class for Riverpod using Freezed.
  static String generateState(
    String featureName,
    FcliConfig config, {
    String? entityName,
  }) {
    final name = entityName ?? featureName;
    final pascalName = StringUtils.toPascalCase(name);
    final snakeName = StringUtils.toSnakeCase(name);
    final featureSnake = StringUtils.toSnakeCase(featureName);
    final camelName = StringUtils.toCamelCase(name);
    final pluralCamel = StringUtils.toPlural(camelName);
    final projectName = config.projectName;

    return '''
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:$projectName/features/$featureSnake/domain/entities/${snakeName}_entity.dart';

part '${snakeName}_state.freezed.dart';

/// State for $pascalName.
@freezed
sealed class ${pascalName}State with _\$${pascalName}State {
  const factory ${pascalName}State({
    @Default([]) List<${pascalName}Entity> $pluralCamel,
    ${pascalName}Entity? selected$pascalName,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _${pascalName}State;

  const ${pascalName}State._();

  bool get hasError => errorMessage != null;
  bool get isEmpty => $pluralCamel.isEmpty;
}
''';
  }

  /// Generates Bloc events.
  static String generateBlocEvents(String featureName, {String? entityName}) {
    final name = entityName ?? featureName;
    final pascalName = StringUtils.toPascalCase(name);
    final snakeName = StringUtils.toSnakeCase(name);

    return '''
part of '${snakeName}_bloc.dart';

/// Base event for $pascalName BLoC.
abstract class ${pascalName}Event extends Equatable {
  const ${pascalName}Event();

  @override
  List<Object?> get props => [];
}

/// Event to load all ${pascalName}s.
class Load${pascalName}s extends ${pascalName}Event {
  const Load${pascalName}s();
}

/// Event to load a single $pascalName.
class Load$pascalName extends ${pascalName}Event {
  const Load$pascalName(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

/// Event to create a $pascalName.
class Create$pascalName extends ${pascalName}Event {
  const Create$pascalName(this.entity);

  final ${pascalName}Entity entity;

  @override
  List<Object?> get props => [entity];
}

/// Event to update a $pascalName.
class Update$pascalName extends ${pascalName}Event {
  const Update$pascalName(this.entity);

  final ${pascalName}Entity entity;

  @override
  List<Object?> get props => [entity];
}

/// Event to delete a $pascalName.
class Delete$pascalName extends ${pascalName}Event {
  const Delete$pascalName(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
''';
  }

  /// Generates Bloc states.
  static String generateBlocStates(String featureName, {String? entityName}) {
    final name = entityName ?? featureName;
    final pascalName = StringUtils.toPascalCase(name);
    final snakeName = StringUtils.toSnakeCase(name);
    final camelName = StringUtils.toCamelCase(name);

    return '''
part of '${snakeName}_bloc.dart';

/// Base state for $pascalName BLoC.
abstract class ${pascalName}State extends Equatable {
  const ${pascalName}State();

  @override
  List<Object?> get props => [];
}

/// Initial state.
class ${pascalName}Initial extends ${pascalName}State {
  const ${pascalName}Initial();
}

/// Loading state.
class ${pascalName}Loading extends ${pascalName}State {
  const ${pascalName}Loading();
}

/// State when ${pascalName}s are loaded.
class ${pascalName}Loaded extends ${pascalName}State {
  const ${pascalName}Loaded(this.${camelName}s);

  final List<${pascalName}Entity> ${camelName}s;

  @override
  List<Object?> get props => [${camelName}s];
}

/// State when a single $pascalName is loaded.
class ${pascalName}DetailLoaded extends ${pascalName}State {
  const ${pascalName}DetailLoaded(this.$camelName);

  final ${pascalName}Entity $camelName;

  @override
  List<Object?> get props => [$camelName];
}

/// State when a $pascalName is created.
class ${pascalName}Created extends ${pascalName}State {
  const ${pascalName}Created(this.$camelName);

  final ${pascalName}Entity $camelName;

  @override
  List<Object?> get props => [$camelName];
}

/// State when a $pascalName is updated.
class ${pascalName}Updated extends ${pascalName}State {
  const ${pascalName}Updated(this.$camelName);

  final ${pascalName}Entity $camelName;

  @override
  List<Object?> get props => [$camelName];
}

/// State when a $pascalName is deleted.
class ${pascalName}Deleted extends ${pascalName}State {
  const ${pascalName}Deleted(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

/// Error state.
class ${pascalName}Error extends ${pascalName}State {
  const ${pascalName}Error(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
''';
  }
}
