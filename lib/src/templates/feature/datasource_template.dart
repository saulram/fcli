import '../../config/fcli_config.dart';
import '../../utils/string_utils.dart';

/// Template for generating data/datasources/<feature>_remote_datasource.dart
class DataSourceTemplate {
  DataSourceTemplate._();

  /// Generates a remote data source class.
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
    final pluralSnake = StringUtils.toPlural(snakeName);
    final projectName = config.projectName;

    if (config.useDioClient) {
      return _generateDioDataSource(
        pascalName,
        snakeName,
        featureSnake,
        pluralSnake,
        projectName,
      );
    } else {
      return _generateHttpDataSource(
        pascalName,
        snakeName,
        featureSnake,
        pluralSnake,
        projectName,
      );
    }
  }

  static String _generateDioDataSource(
    String pascalName,
    String snakeName,
    String featureSnake,
    String pluralSnake,
    String projectName,
  ) =>
      '''
import 'package:dio/dio.dart';

import 'package:$projectName/core/error/exceptions.dart';
import 'package:$projectName/features/$featureSnake/data/models/${snakeName}_model.dart';

/// Remote data source for $pascalName using Dio.
abstract class ${pascalName}RemoteDataSource {
  Future<List<${pascalName}Model>> getAll();
  Future<${pascalName}Model> getById(String id);
  Future<${pascalName}Model> create(${pascalName}Model model);
  Future<${pascalName}Model> update(${pascalName}Model model);
  Future<void> delete(String id);
}

/// Implementation of [${pascalName}RemoteDataSource] using Dio.
class ${pascalName}RemoteDataSourceImpl implements ${pascalName}RemoteDataSource {
  const ${pascalName}RemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;
  static const String _endpoint = '/$pluralSnake';

  @override
  Future<List<${pascalName}Model>> getAll() async {
    try {
      final response = await _dio.get<List<dynamic>>(_endpoint);
      if (response.data == null) {
        throw const ServerException('No data received');
      }
      return response.data!
          .map((json) => ${pascalName}Model.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<${pascalName}Model> getById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('\$_endpoint/\$id');
      if (response.data == null) {
        throw const NotFoundException();
      }
      return ${pascalName}Model.fromJson(response.data!);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<${pascalName}Model> create(${pascalName}Model model) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _endpoint,
        data: model.toJson(),
      );
      if (response.data == null) {
        throw const ServerException('No data received');
      }
      return ${pascalName}Model.fromJson(response.data!);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<${pascalName}Model> update(${pascalName}Model model) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '\$_endpoint/\${model.id}',
        data: model.toJson(),
      );
      if (response.data == null) {
        throw const ServerException('No data received');
      }
      return ${pascalName}Model.fromJson(response.data!);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete<void>('\$_endpoint/\$id');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  AppException _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 404) {
          return const NotFoundException();
        }
        if (statusCode == 401) {
          return const UnauthorizedException();
        }
        if (statusCode == 422) {
          return const ValidationException();
        }
        return ServerException(e.message);
      default:
        return ServerException(e.message);
    }
  }
}
''';

  static String _generateHttpDataSource(
    String pascalName,
    String snakeName,
    String featureSnake,
    String pluralSnake,
    String projectName,
  ) =>
      '''
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:$projectName/core/error/exceptions.dart';
import 'package:$projectName/features/$featureSnake/data/models/${snakeName}_model.dart';

/// Remote data source for $pascalName using http package.
abstract class ${pascalName}RemoteDataSource {
  Future<List<${pascalName}Model>> getAll();
  Future<${pascalName}Model> getById(String id);
  Future<${pascalName}Model> create(${pascalName}Model model);
  Future<${pascalName}Model> update(${pascalName}Model model);
  Future<void> delete(String id);
}

/// Implementation of [${pascalName}RemoteDataSource] using http.
class ${pascalName}RemoteDataSourceImpl implements ${pascalName}RemoteDataSource {
  const ${pascalName}RemoteDataSourceImpl({
    required http.Client client,
    required String baseUrl,
  }) : _client = client, _baseUrl = baseUrl;

  final http.Client _client;
  final String _baseUrl;
  static const String _endpoint = '/$pluralSnake';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  @override
  Future<List<${pascalName}Model>> getAll() async {
    final response = await _client.get(
      Uri.parse('\$_baseUrl\$_endpoint'),
      headers: _headers,
    );
    _handleResponse(response);
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((json) => ${pascalName}Model.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<${pascalName}Model> getById(String id) async {
    final response = await _client.get(
      Uri.parse('\$_baseUrl\$_endpoint/\$id'),
      headers: _headers,
    );
    _handleResponse(response);
    return ${pascalName}Model.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<${pascalName}Model> create(${pascalName}Model model) async {
    final response = await _client.post(
      Uri.parse('\$_baseUrl\$_endpoint'),
      headers: _headers,
      body: jsonEncode(model.toJson()),
    );
    _handleResponse(response);
    return ${pascalName}Model.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<${pascalName}Model> update(${pascalName}Model model) async {
    final response = await _client.put(
      Uri.parse('\$_baseUrl\$_endpoint/\${model.id}'),
      headers: _headers,
      body: jsonEncode(model.toJson()),
    );
    _handleResponse(response);
    return ${pascalName}Model.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> delete(String id) async {
    final response = await _client.delete(
      Uri.parse('\$_baseUrl\$_endpoint/\$id'),
      headers: _headers,
    );
    _handleResponse(response);
  }

  void _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    switch (response.statusCode) {
      case 404:
        throw const NotFoundException();
      case 401:
        throw const UnauthorizedException();
      case 422:
        throw const ValidationException();
      default:
        throw ServerException('Server error: \${response.statusCode}');
    }
  }
}
''';

  /// Generates a local data source for caching.
  static String generateLocal(
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
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:$projectName/core/error/exceptions.dart';
import 'package:$projectName/features/$featureSnake/data/models/${snakeName}_model.dart';

/// Local data source for caching $pascalName data.
abstract class ${pascalName}LocalDataSource {
  Future<List<${pascalName}Model>> getCached();
  Future<void> cache(List<${pascalName}Model> models);
  Future<void> clear();
}

/// Implementation of [${pascalName}LocalDataSource] using SharedPreferences.
class ${pascalName}LocalDataSourceImpl implements ${pascalName}LocalDataSource {
  const ${pascalName}LocalDataSourceImpl({
    required SharedPreferences sharedPreferences,
  }) : _sharedPreferences = sharedPreferences;

  final SharedPreferences _sharedPreferences;
  static const String _cacheKey = 'CACHED_${snakeName.toUpperCase()}S';

  @override
  Future<List<${pascalName}Model>> getCached() async {
    final jsonString = _sharedPreferences.getString(_cacheKey);
    if (jsonString == null) {
      throw const CacheException('No cached data');
    }
    final jsonList = jsonDecode(jsonString) as List<dynamic>;
    return jsonList
        .map((json) => ${pascalName}Model.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> cache(List<${pascalName}Model> models) async {
    final jsonList = models.map((model) => model.toJson()).toList();
    await _sharedPreferences.setString(_cacheKey, jsonEncode(jsonList));
  }

  @override
  Future<void> clear() async {
    await _sharedPreferences.remove(_cacheKey);
  }
}
''';
  }
}
