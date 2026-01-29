import '../../config/fcli_config.dart';
import '../../utils/string_utils.dart';

/// Template for generating data/repositories/<feature>_repository_impl.dart
class RepositoryImplTemplate {
  RepositoryImplTemplate._();

  /// Generates a repository implementation class.
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
    final pascalName = StringUtils.toPascalCase(name);
    final snakeName = StringUtils.toSnakeCase(name);
    final featureSnake = StringUtils.toSnakeCase(featureName);
    final projectName = config.projectName;

    return '''
import 'package:dartz/dartz.dart';

import 'package:$projectName/core/error/exceptions.dart';
import 'package:$projectName/core/error/failures.dart';
import 'package:$projectName/features/$featureSnake/domain/entities/${snakeName}_entity.dart';
import 'package:$projectName/features/$featureSnake/domain/repositories/${snakeName}_repository.dart';
import 'package:$projectName/features/$featureSnake/data/datasources/${snakeName}_remote_datasource.dart';
import 'package:$projectName/features/$featureSnake/data/models/${snakeName}_model.dart';

/// Implementation of [${pascalName}Repository].
class ${pascalName}RepositoryImpl implements ${pascalName}Repository {
  const ${pascalName}RepositoryImpl({
    required ${pascalName}RemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final ${pascalName}RemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, List<${pascalName}Entity>>> getAll() async {
    try {
      final models = await _remoteDataSource.getAll();
      final entities = models.map((model) => model.toEntity()).toList();
      return Right(entities);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message ?? 'Server error'));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message ?? 'Network error'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ${pascalName}Entity>> getById(String id) async {
    try {
      final model = await _remoteDataSource.getById(id);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message ?? 'Server error'));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message ?? 'Not found'));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message ?? 'Network error'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ${pascalName}Entity>> create(${pascalName}Entity entity) async {
    try {
      final model = ${pascalName}Model.fromEntity(entity);
      final result = await _remoteDataSource.create(model);
      return Right(result.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message ?? 'Server error'));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message ?? 'Validation failed'));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message ?? 'Network error'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ${pascalName}Entity>> update(${pascalName}Entity entity) async {
    try {
      final model = ${pascalName}Model.fromEntity(entity);
      final result = await _remoteDataSource.update(model);
      return Right(result.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message ?? 'Server error'));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message ?? 'Not found'));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message ?? 'Validation failed'));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message ?? 'Network error'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    try {
      await _remoteDataSource.delete(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message ?? 'Server error'));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message ?? 'Not found'));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message ?? 'Network error'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
''';
  }
}
