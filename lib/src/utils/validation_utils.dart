import 'package:path/path.dart' as p;

/// Security validation utilities to prevent common vulnerabilities.
class ValidationUtils {
  ValidationUtils._();

  // ============================================================
  // Reserved/Dangerous Names
  // ============================================================

  /// Reserved names that should not be used as project names.
  static const _reservedProjectNames = <String>{
    // Dart/Flutter reserved
    'dart',
    'flutter',
    'test',
    'build',
    'lib',
    'bin',
    'web',
    'ios',
    'android',
    'linux',
    'macos',
    'windows',
    // System reserved
    'con',
    'prn',
    'aux',
    'nul',
    'com1',
    'com2',
    'com3',
    'com4',
    'com5',
    'com6',
    'com7',
    'com8',
    'com9',
    'lpt1',
    'lpt2',
    'lpt3',
    'lpt4',
    'lpt5',
    'lpt6',
    'lpt7',
    'lpt8',
    'lpt9',
    // Common dangerous
    'null',
    'undefined',
    'true',
    'false',
  };

  // ============================================================
  // Path Validation
  // ============================================================

  /// Validates that a path does not contain path traversal sequences.
  /// Returns null if valid, or an error message if invalid.
  static String? validatePath(String path, {String? basePath}) {
    // Check for null bytes
    if (path.contains('\x00')) {
      return 'Path contains null bytes';
    }

    // Check for path traversal sequences
    final normalized = p.normalize(path);
    if (normalized.contains('..')) {
      return 'Path contains directory traversal sequences';
    }

    // If base path provided, ensure the path stays within it
    if (basePath != null) {
      final absolutePath = p.isAbsolute(path) ? path : p.join(basePath, path);
      final resolvedPath = p.normalize(p.absolute(absolutePath));
      final resolvedBase = p.normalize(p.absolute(basePath));

      if (!resolvedPath.startsWith(resolvedBase)) {
        return 'Path escapes base directory';
      }
    }

    return null;
  }

  /// Checks if a path is safe (no traversal, within optional base).
  static bool isPathSafe(String path, {String? basePath}) {
    return validatePath(path, basePath: basePath) == null;
  }

  // ============================================================
  // Project Name Validation
  // ============================================================

  /// Validates a Dart/Flutter project name.
  /// Returns null if valid, or an error message if invalid.
  static String? validateProjectName(String name) {
    // Check length
    if (name.isEmpty) {
      return 'Project name cannot be empty';
    }
    if (name.length > 64) {
      return 'Project name must be 64 characters or less';
    }

    // Check format (valid Dart package name)
    if (!RegExp(r'^[a-z_][a-z0-9_]*$').hasMatch(name)) {
      return 'Project name must be lowercase with underscores only, '
          'starting with a letter or underscore';
    }

    // Check reserved names
    if (_reservedProjectNames.contains(name.toLowerCase())) {
      return 'Project name "$name" is reserved';
    }

    // Check for consecutive underscores
    if (name.contains('__')) {
      return 'Project name cannot contain consecutive underscores';
    }

    // Check it doesn't start or end with underscore (convention)
    if (name.startsWith('_') && name.length > 1 && name[1] == '_') {
      return 'Project name should not start with multiple underscores';
    }

    return null;
  }

  /// Checks if a project name is valid.
  static bool isValidProjectName(String name) {
    return validateProjectName(name) == null;
  }

  // ============================================================
  // Task Name Validation
  // ============================================================

  /// Validates a task name for git worktree operations.
  /// Returns null if valid, or an error message if invalid.
  static String? validateTaskName(String name) {
    // Check length
    if (name.isEmpty) {
      return 'Task name cannot be empty';
    }
    if (name.length > 50) {
      return 'Task name must be 50 characters or less';
    }

    // Only allow alphanumeric, hyphen, and underscore
    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_-]*$').hasMatch(name)) {
      return 'Task name must start with a letter and contain only '
          'letters, numbers, hyphens, and underscores';
    }

    // No path traversal
    if (name.contains('..') || name.contains('/') || name.contains('\\')) {
      return 'Task name cannot contain path separators';
    }

    return null;
  }

  /// Checks if a task name is valid.
  static bool isValidTaskName(String name) {
    return validateTaskName(name) == null;
  }

  // ============================================================
  // Git Branch Name Validation
  // ============================================================

  /// Validates a git branch name according to git-check-ref-format rules.
  /// Returns null if valid, or an error message if invalid.
  static String? validateBranchName(String name) {
    // Check length
    if (name.isEmpty) {
      return 'Branch name cannot be empty';
    }
    if (name.length > 255) {
      return 'Branch name must be 255 characters or less';
    }

    // Cannot start with hyphen
    if (name.startsWith('-')) {
      return 'Branch name cannot start with a hyphen';
    }

    // Cannot start or end with slash
    if (name.startsWith('/') || name.endsWith('/')) {
      return 'Branch name cannot start or end with a slash';
    }

    // Cannot contain consecutive slashes
    if (name.contains('//')) {
      return 'Branch name cannot contain consecutive slashes';
    }

    // Cannot end with .lock
    if (name.endsWith('.lock')) {
      return 'Branch name cannot end with .lock';
    }

    // Cannot contain these sequences
    final forbidden = ['..', '@{', '\\', ' ', '~', '^', ':', '?', '*', '['];
    for (final seq in forbidden) {
      if (name.contains(seq)) {
        return 'Branch name cannot contain "$seq"';
      }
    }

    // Cannot contain control characters or DEL
    for (var i = 0; i < name.length; i++) {
      final code = name.codeUnitAt(i);
      if (code < 32 || code == 127) {
        return 'Branch name cannot contain control characters';
      }
    }

    // Components cannot start with dot
    final components = name.split('/');
    for (final component in components) {
      if (component.startsWith('.')) {
        return 'Branch name components cannot start with a dot';
      }
      if (component.endsWith('.')) {
        return 'Branch name components cannot end with a dot';
      }
    }

    return null;
  }

  /// Checks if a git branch name is valid.
  static bool isValidBranchName(String name) {
    return validateBranchName(name) == null;
  }

  // ============================================================
  // General Input Sanitization
  // ============================================================

  /// Sanitizes a string for safe console output by removing ANSI escape codes
  /// and control characters.
  static String sanitizeForConsole(String input) {
    // Remove ANSI escape codes
    final ansiPattern = RegExp(r'\x1B\[[0-9;]*[a-zA-Z]');
    var result = input.replaceAll(ansiPattern, '');

    // Remove control characters except newline and tab
    final buffer = StringBuffer();
    for (var i = 0; i < result.length; i++) {
      final code = result.codeUnitAt(i);
      if (code >= 32 || code == 10 || code == 9) {
        // 10 = newline, 9 = tab
        buffer.writeCharCode(code);
      }
    }

    return buffer.toString();
  }
}
