import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../config/config_loader.dart';
import '../config/fcli_config.dart';
import '../utils/console_utils.dart';
import '../utils/file_utils.dart';
import '../utils/process_utils.dart';
import '../utils/string_utils.dart';

/// Command for validating the local FLG/Flutter project setup.
class DoctorCommand extends Command<int> {
  DoctorCommand() {
    argParser
      ..addFlag(
        'json',
        help: 'Print machine-readable JSON output.',
        negatable: false,
      )
      ..addFlag(
        'analyze',
        help: 'Run flutter analyze as part of the checks.',
        negatable: false,
      );
  }

  @override
  String get name => 'doctor';

  @override
  String get description => 'Check FLG project health and local tooling.';

  @override
  Future<int> run() async {
    final jsonOutput = argResults!['json'] as bool;
    final runAnalyze = argResults!['analyze'] as bool;
    final checks = <_DoctorCheck>[];

    checks.add(await _toolCheck('Dart SDK', ProcessUtils.isDartInstalled));
    checks
        .add(await _toolCheck('Flutter SDK', ProcessUtils.isFlutterInstalled));

    final projectPath = ConfigLoader.findConfigPath();
    if (projectPath == null) {
      checks.add(
        const _DoctorCheck(
          name: 'FLG project',
          status: _DoctorStatus.warning,
          message: 'No flg.json found from the current directory.',
        ),
      );
      return _finish(checks, jsonOutput: jsonOutput);
    }

    checks.add(
      _DoctorCheck(
        name: 'FLG project',
        status: _DoctorStatus.pass,
        message: projectPath,
      ),
    );

    final config = ConfigLoader.load(projectPath);
    if (config == null) {
      checks.add(
        const _DoctorCheck(
          name: 'Configuration',
          status: _DoctorStatus.fail,
          message: 'flg.json could not be parsed.',
        ),
      );
      return _finish(checks, jsonOutput: jsonOutput);
    }

    checks
      ..add(_configCheck(config))
      ..add(_fileCheck(projectPath, 'pubspec.yaml'))
      ..add(_fileCheck(projectPath, p.join('lib', 'main.dart')))
      ..add(_directoryCheck(projectPath, p.join('lib', 'features')))
      ..add(_dependencyCheck(projectPath, config));

    for (final feature in config.features) {
      checks.add(_featureCheck(projectPath, feature));
    }

    if (runAnalyze) {
      checks.add(await _analyzeCheck(projectPath));
    }

    return _finish(checks, jsonOutput: jsonOutput);
  }

  Future<_DoctorCheck> _toolCheck(
    String name,
    Future<bool> Function() check,
  ) async {
    final installed = await check();
    return _DoctorCheck(
      name: name,
      status: installed ? _DoctorStatus.pass : _DoctorStatus.warning,
      message: installed ? 'Available' : 'Not found in PATH',
    );
  }

  _DoctorCheck _configCheck(FcliConfig config) {
    final errors = ConfigLoader.validate(config);
    if (errors.isEmpty) {
      return const _DoctorCheck(
        name: 'Configuration',
        status: _DoctorStatus.pass,
        message: 'flg.json is valid.',
      );
    }
    return _DoctorCheck(
      name: 'Configuration',
      status: _DoctorStatus.fail,
      message: errors.join('; '),
    );
  }

  _DoctorCheck _fileCheck(String projectPath, String relativePath) {
    final exists = FileUtils.fileExistsSync(p.join(projectPath, relativePath));
    return _DoctorCheck(
      name: relativePath,
      status: exists ? _DoctorStatus.pass : _DoctorStatus.fail,
      message: exists ? 'Found' : 'Missing',
    );
  }

  _DoctorCheck _directoryCheck(String projectPath, String relativePath) {
    final exists =
        FileUtils.directoryExistsSync(p.join(projectPath, relativePath));
    return _DoctorCheck(
      name: relativePath,
      status: exists ? _DoctorStatus.pass : _DoctorStatus.fail,
      message: exists ? 'Found' : 'Missing',
    );
  }

  _DoctorCheck _dependencyCheck(String projectPath, FcliConfig config) {
    final pubspecPath = p.join(projectPath, 'pubspec.yaml');
    if (!FileUtils.fileExistsSync(pubspecPath)) {
      return const _DoctorCheck(
        name: 'Dependencies',
        status: _DoctorStatus.fail,
        message: 'pubspec.yaml is missing.',
      );
    }

    final content = FileUtils.readFileSync(pubspecPath);
    final expected = <String>[
      'equatable:',
      'dartz:',
      if (config.usesRiverpod) 'flutter_riverpod:',
      if (config.usesBloc) 'flutter_bloc:',
      if (config.usesProvider) 'provider:',
      if (config.usesGoRouter) 'go_router:',
      if (config.usesAutoRoute) 'auto_route:',
      if (config.useFreezed) 'freezed_annotation:',
      if (config.useDioClient) 'dio:' else 'http:',
    ];

    final missing = expected.where((dep) => !content.contains(dep)).toList();
    if (missing.isEmpty) {
      return const _DoctorCheck(
        name: 'Dependencies',
        status: _DoctorStatus.pass,
        message: 'Expected dependencies found.',
      );
    }

    return _DoctorCheck(
      name: 'Dependencies',
      status: _DoctorStatus.warning,
      message: 'Missing: ${missing.join(', ')}',
    );
  }

  _DoctorCheck _featureCheck(String projectPath, String feature) {
    final snakeFeature = StringUtils.toSnakeCase(feature);
    final featurePath = p.join(projectPath, 'lib', 'features', snakeFeature);
    final exists = FileUtils.directoryExistsSync(featurePath);
    return _DoctorCheck(
      name: 'Feature $feature',
      status: exists ? _DoctorStatus.pass : _DoctorStatus.warning,
      message: exists ? 'Found' : 'Directory missing at $featurePath',
    );
  }

  Future<_DoctorCheck> _analyzeCheck(String projectPath) async {
    final result = await ProcessUtils.flutterAnalyze(
      workingDirectory: projectPath,
    );
    return _DoctorCheck(
      name: 'flutter analyze',
      status: result.success ? _DoctorStatus.pass : _DoctorStatus.fail,
      message: result.success ? 'No issues found.' : result.stderr,
    );
  }

  int _finish(
    List<_DoctorCheck> checks, {
    required bool jsonOutput,
  }) {
    final hasFailure =
        checks.any((check) => check.status == _DoctorStatus.fail);
    final hasWarning =
        checks.any((check) => check.status == _DoctorStatus.warning);

    if (jsonOutput) {
      print(
        const JsonEncoder.withIndent('  ').convert({
          'status': hasFailure
              ? 'fail'
              : hasWarning
                  ? 'warning'
                  : 'pass',
          'checks': checks.map((check) => check.toJson()).toList(),
        }),
      );
    } else {
      ConsoleUtils.header('FLG Doctor');
      for (final check in checks) {
        switch (check.status) {
          case _DoctorStatus.pass:
            ConsoleUtils.success('${check.name}: ${check.message}');
          case _DoctorStatus.warning:
            ConsoleUtils.warning('${check.name}: ${check.message}');
          case _DoctorStatus.fail:
            ConsoleUtils.error('${check.name}: ${check.message}');
        }
      }
    }

    return hasFailure ? 1 : 0;
  }
}

enum _DoctorStatus {
  pass,
  warning,
  fail;
}

class _DoctorCheck {
  const _DoctorCheck({
    required this.name,
    required this.status,
    required this.message,
  });

  final String name;
  final _DoctorStatus status;
  final String message;

  Map<String, String> toJson() => {
        'name': name,
        'status': status.name,
        'message': message,
      };
}
