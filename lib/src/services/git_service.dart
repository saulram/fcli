import 'dart:io';

import '../utils/process_utils.dart';
import '../utils/validation_utils.dart';

/// Information about a git worktree.
class WorktreeInfo {
  const WorktreeInfo({
    required this.path,
    required this.branch,
    required this.head,
    this.isBare = false,
  });

  final String path;
  final String branch;
  final String head;
  final bool isBare;

  @override
  String toString() => 'WorktreeInfo(path: $path, branch: $branch)';
}

/// Service for git operations.
class GitService {
  GitService._();

  /// Checks if a path is inside a git repository.
  static Future<bool> isGitRepo(String path) async {
    final result = await ProcessUtils.run(
      'git',
      ['rev-parse', '--is-inside-work-tree'],
      workingDirectory: path,
    );
    return result.success && result.stdout.trim() == 'true';
  }

  /// Gets the root directory of the git repository.
  static Future<String?> getRepoRoot(String path) async {
    final result = await ProcessUtils.run(
      'git',
      ['rev-parse', '--show-toplevel'],
      workingDirectory: path,
    );
    if (result.success) {
      return result.stdout.trim();
    }
    return null;
  }

  /// Gets the current branch name.
  static Future<String> getCurrentBranch(String path) async {
    final result = await ProcessUtils.run(
      'git',
      ['rev-parse', '--abbrev-ref', 'HEAD'],
      workingDirectory: path,
    );
    if (result.success) {
      return result.stdout.trim();
    }
    return 'HEAD';
  }

  /// Gets the main branch name (main or master).
  static Future<String> getMainBranch(String path) async {
    // Try to get the default branch from origin
    var result = await ProcessUtils.run(
      'git',
      ['symbolic-ref', 'refs/remotes/origin/HEAD', '--short'],
      workingDirectory: path,
    );

    if (result.success) {
      final branch = result.stdout.trim();
      // Returns something like "origin/main", extract just "main"
      return branch.replaceFirst('origin/', '');
    }

    // Fallback: check if main exists
    result = await ProcessUtils.run(
      'git',
      ['show-ref', '--verify', '--quiet', 'refs/heads/main'],
      workingDirectory: path,
    );

    if (result.success) {
      return 'main';
    }

    // Check if master exists
    result = await ProcessUtils.run(
      'git',
      ['show-ref', '--verify', '--quiet', 'refs/heads/master'],
      workingDirectory: path,
    );

    if (result.success) {
      return 'master';
    }

    // Default to main
    return 'main';
  }

  /// Creates a new worktree with a branch.
  ///
  /// Throws [ArgumentError] if branch name is invalid.
  static Future<ProcessResult> worktreeAdd(
    String worktreePath,
    String branch, {
    String? baseBranch,
    String? repoPath,
  }) async {
    // Validate branch name before passing to git
    final branchError = ValidationUtils.validateBranchName(branch);
    if (branchError != null) {
      throw ArgumentError('Invalid branch name: $branchError');
    }

    if (baseBranch != null) {
      final baseError = ValidationUtils.validateBranchName(baseBranch);
      if (baseError != null) {
        throw ArgumentError('Invalid base branch name: $baseError');
      }
    }

    final args = ['worktree', 'add'];

    if (baseBranch != null) {
      args.addAll(['-b', branch, worktreePath, baseBranch]);
    } else {
      args.addAll(['-b', branch, worktreePath]);
    }

    return ProcessUtils.run(
      'git',
      args,
      workingDirectory: repoPath ?? Directory.current.path,
    );
  }

  /// Removes a worktree.
  static Future<ProcessResult> worktreeRemove(
    String worktreePath, {
    bool force = false,
    String? repoPath,
  }) async {
    final args = ['worktree', 'remove'];
    if (force) {
      args.add('--force');
    }
    args.add(worktreePath);

    return ProcessUtils.run(
      'git',
      args,
      workingDirectory: repoPath ?? Directory.current.path,
    );
  }

  /// Prunes worktree information.
  static Future<ProcessResult> worktreePrune({String? repoPath}) async {
    return ProcessUtils.run(
      'git',
      ['worktree', 'prune'],
      workingDirectory: repoPath ?? Directory.current.path,
    );
  }

  /// Lists all worktrees in a repository.
  static Future<List<WorktreeInfo>> worktreeList(String repoPath) async {
    final result = await ProcessUtils.run(
      'git',
      ['worktree', 'list', '--porcelain'],
      workingDirectory: repoPath,
    );

    if (result.failed) {
      return [];
    }

    final worktrees = <WorktreeInfo>[];
    final lines = result.stdout.split('\n');

    String? currentPath;
    String? currentHead;
    String? currentBranch;
    var isBare = false;

    for (final line in lines) {
      if (line.startsWith('worktree ')) {
        currentPath = line.substring('worktree '.length);
      } else if (line.startsWith('HEAD ')) {
        currentHead = line.substring('HEAD '.length);
      } else if (line.startsWith('branch ')) {
        // Branch format: refs/heads/branch-name
        final branch = line.substring('branch '.length);
        currentBranch = branch.replaceFirst('refs/heads/', '');
      } else if (line == 'bare') {
        isBare = true;
      } else if (line.startsWith('detached')) {
        currentBranch = 'detached';
      } else if (line.isEmpty && currentPath != null) {
        // End of worktree entry
        worktrees.add(WorktreeInfo(
          path: currentPath,
          head: currentHead ?? '',
          branch: currentBranch ?? 'detached',
          isBare: isBare,
        ));
        currentPath = null;
        currentHead = null;
        currentBranch = null;
        isBare = false;
      }
    }

    // Handle last entry if no trailing newline
    if (currentPath != null) {
      worktrees.add(WorktreeInfo(
        path: currentPath,
        head: currentHead ?? '',
        branch: currentBranch ?? 'detached',
        isBare: isBare,
      ));
    }

    return worktrees;
  }

  /// Gets the number of commits ahead and behind relative to a base branch.
  static Future<(int ahead, int behind)> getBranchStatus(
    String path,
    String baseBranch,
  ) async {
    final currentBranch = await getCurrentBranch(path);

    final result = await ProcessUtils.run(
      'git',
      ['rev-list', '--left-right', '--count', '$baseBranch...$currentBranch'],
      workingDirectory: path,
    );

    if (result.failed) {
      return (0, 0);
    }

    final parts = result.stdout.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final behind = int.tryParse(parts[0]) ?? 0;
      final ahead = int.tryParse(parts[1]) ?? 0;
      return (ahead, behind);
    }

    return (0, 0);
  }

  /// Checks if the working directory has uncommitted changes.
  static Future<bool> hasUncommittedChanges(String path) async {
    final result = await ProcessUtils.run(
      'git',
      ['status', '--porcelain'],
      workingDirectory: path,
    );

    return result.success && result.stdout.trim().isNotEmpty;
  }

  /// Checks if a branch exists.
  ///
  /// Returns false if the branch name is invalid.
  static Future<bool> branchExists(String path, String branch) async {
    // Validate branch name before passing to git
    final branchError = ValidationUtils.validateBranchName(branch);
    if (branchError != null) {
      return false;
    }

    final result = await ProcessUtils.run(
      'git',
      ['show-ref', '--verify', '--quiet', 'refs/heads/$branch'],
      workingDirectory: path,
    );
    return result.success;
  }

  /// Deletes a branch.
  ///
  /// Throws [ArgumentError] if branch name is invalid.
  static Future<ProcessResult> deleteBranch(
    String path,
    String branch, {
    bool force = false,
  }) async {
    // Validate branch name before passing to git
    final branchError = ValidationUtils.validateBranchName(branch);
    if (branchError != null) {
      throw ArgumentError('Invalid branch name: $branchError');
    }

    return ProcessUtils.run(
      'git',
      ['branch', force ? '-D' : '-d', branch],
      workingDirectory: path,
    );
  }

  /// Gets the project name from the repository directory.
  static String getProjectName(String repoPath) {
    return Directory(repoPath).uri.pathSegments.lastWhere(
          (s) => s.isNotEmpty,
          orElse: () => 'project',
        );
  }
}
