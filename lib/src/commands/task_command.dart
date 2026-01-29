import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../models/task_info.dart';
import '../services/git_service.dart';
import '../utils/console_utils.dart';
import '../utils/process_utils.dart';
import '../utils/validation_utils.dart';

/// Command for managing git worktrees for AI agent workflows.
class TaskCommand extends Command<int> {
  TaskCommand() {
    addSubcommand(TaskAddCommand());
    addSubcommand(TaskListCommand());
    addSubcommand(TaskRemoveCommand());
    addSubcommand(TaskStatusCommand());
  }

  @override
  String get name => 'task';

  @override
  List<String> get aliases => ['t'];

  @override
  String get description =>
      'Manage git worktrees for AI agent workflows (add, list, remove, status).';
}

/// Subcommand for creating a new task worktree.
class TaskAddCommand extends Command<int> {
  TaskAddCommand() {
    argParser
      ..addOption(
        'type',
        abbr: 't',
        help: 'Branch type prefix (feat, fix, ref).',
        allowed: ['feat', 'fix', 'ref'],
        defaultsTo: 'feat',
      )
      ..addFlag(
        'agent',
        abbr: 'a',
        help: 'Setup for AI agent (runs flutter pub get, creates .claude/TASK.md).',
        negatable: false,
      )
      ..addOption(
        'base',
        abbr: 'b',
        help: 'Base branch to create from.',
      )
      ..addFlag(
        'dry-run',
        help: 'Show what would be created without making changes.',
        negatable: false,
      );
  }

  @override
  String get name => 'add';

  @override
  String get description => 'Create a new task worktree with a branch.';

  @override
  String get invocation => 'flg task add <name> [--type feat|fix|ref] [--agent]';

  @override
  Future<int> run() async {
    if (argResults!.rest.isEmpty) {
      ConsoleUtils.error('Please provide a task name.');
      ConsoleUtils.info('Usage: flg task add <name>');
      return 1;
    }

    final taskName = argResults!.rest.first;
    final typeStr = argResults!['type'] as String;
    final withAgent = argResults!['agent'] as bool;
    final baseBranchArg = argResults!['base'] as String?;
    final dryRun = argResults!['dry-run'] as bool;

    // Validate task name to prevent path traversal
    final taskNameError = ValidationUtils.validateTaskName(taskName);
    if (taskNameError != null) {
      ConsoleUtils.error(taskNameError);
      return 1;
    }

    final currentDir = Directory.current.path;

    // Verify we're in a git repo
    if (!await GitService.isGitRepo(currentDir)) {
      ConsoleUtils.error('Not a git repository.');
      ConsoleUtils.info('Run this command from within a git repository.');
      return 1;
    }

    final repoRoot = await GitService.getRepoRoot(currentDir);
    if (repoRoot == null) {
      ConsoleUtils.error('Could not determine repository root.');
      return 1;
    }

    final taskType = TaskType.fromString(typeStr);
    final baseBranch = baseBranchArg ?? await GitService.getMainBranch(repoRoot);
    final branchName = '${taskType.branchPrefix}/$taskName';

    // Validate branch name
    final branchError = ValidationUtils.validateBranchName(branchName);
    if (branchError != null) {
      ConsoleUtils.error('Invalid branch name: $branchError');
      return 1;
    }

    // Check if branch already exists
    if (await GitService.branchExists(repoRoot, branchName)) {
      ConsoleUtils.error('Branch "$branchName" already exists.');
      return 1;
    }

    // Build worktree path: ../project-tasks/type-name/
    final projectName = GitService.getProjectName(repoRoot);
    final tasksDir = p.join(p.dirname(repoRoot), '$projectName-tasks');
    final worktreePath = p.join(tasksDir, '${taskType.branchPrefix}-$taskName');

    // Check if worktree path already exists
    if (Directory(worktreePath).existsSync()) {
      ConsoleUtils.error('Worktree path already exists: $worktreePath');
      return 1;
    }

    if (dryRun) {
      ConsoleUtils.header('Dry Run - Would create:');
      ConsoleUtils.info('Branch: $branchName (from $baseBranch)');
      ConsoleUtils.info('Worktree: $worktreePath');
      if (withAgent) {
        ConsoleUtils.info('Agent setup: flutter pub get + .claude/TASK.md');
      }
      return 0;
    }

    // Create tasks directory if it doesn't exist
    final tasksDirObj = Directory(tasksDir);
    if (!tasksDirObj.existsSync()) {
      tasksDirObj.createSync(recursive: true);
    }

    // Create worktree
    final result = await ConsoleUtils.withSpinner(
      'Creating task: ${taskType.branchPrefix}-$taskName',
      () => GitService.worktreeAdd(
        worktreePath,
        branchName,
        baseBranch: baseBranch,
        repoPath: repoRoot,
      ),
    );

    if (result.failed) {
      ConsoleUtils.error('Failed to create worktree: ${result.stderr}');
      return 1;
    }

    ConsoleUtils.step('Path: $worktreePath');
    ConsoleUtils.step('Branch: $branchName');
    ConsoleUtils.newLine();

    if (withAgent) {
      // Run flutter pub get
      await ConsoleUtils.withSpinner(
        'Running flutter pub get...',
        () => ProcessUtils.flutterPubGet(workingDirectory: worktreePath),
      );

      // Create .claude/TASK.md
      final claudeDir = Directory(p.join(worktreePath, '.claude'));
      if (!claudeDir.existsSync()) {
        claudeDir.createSync(recursive: true);
      }

      final taskMdPath = p.join(claudeDir.path, 'TASK.md');
      final taskMdContent = _generateTaskMd(taskName, branchName, taskType);
      File(taskMdPath).writeAsStringSync(taskMdContent);
      ConsoleUtils.success('Created .claude/TASK.md');

      ConsoleUtils.newLine();
    }

    ConsoleUtils.success('Ready for AI Agent:');
    print(worktreePath);

    return 0;
  }

  String _generateTaskMd(String taskName, String branchName, TaskType type) {
    final typeLabel = switch (type) {
      TaskType.feat => 'Feature',
      TaskType.fix => 'Bug Fix',
      TaskType.ref => 'Refactor',
    };

    return '''# Task: $taskName

## Type
$typeLabel

## Branch
`$branchName`

## Description
<!-- Describe the task here -->

## Acceptance Criteria
- [ ] <!-- Criterion 1 -->
- [ ] <!-- Criterion 2 -->

## Notes
<!-- Any additional context for the AI agent -->
''';
  }
}

/// Subcommand for listing task worktrees.
class TaskListCommand extends Command<int> {
  @override
  String get name => 'list';

  @override
  List<String> get aliases => ['ls'];

  @override
  String get description => 'List all task worktrees.';

  @override
  Future<int> run() async {
    final currentDir = Directory.current.path;

    if (!await GitService.isGitRepo(currentDir)) {
      ConsoleUtils.error('Not a git repository.');
      return 1;
    }

    final repoRoot = await GitService.getRepoRoot(currentDir);
    if (repoRoot == null) {
      ConsoleUtils.error('Could not determine repository root.');
      return 1;
    }

    final worktrees = await GitService.worktreeList(repoRoot);
    final tasks = _filterTaskWorktrees(worktrees, repoRoot);

    if (tasks.isEmpty) {
      ConsoleUtils.info('No task worktrees found.');
      ConsoleUtils.muted('Create one with: flg task add <name>');
      return 0;
    }

    ConsoleUtils.newLine();
    print('${ConsoleUtils.bold('FLG Tasks')} - ${tasks.length} active');
    ConsoleUtils.newLine();

    // Print table header
    print(
      '  ${_padRight('NAME', 20)} ${_padRight('BRANCH', 25)} PATH',
    );
    ConsoleUtils.line(length: 70);

    for (final task in tasks) {
      print(
        '  ${_padRight(task.name, 20)} ${_padRight(task.branch, 25)} ${task.path}',
      );
    }

    ConsoleUtils.newLine();
    return 0;
  }

  List<TaskInfo> _filterTaskWorktrees(
    List<WorktreeInfo> worktrees,
    String repoRoot,
  ) {
    final projectName = GitService.getProjectName(repoRoot);
    final tasksDir = p.join(p.dirname(repoRoot), '$projectName-tasks');
    final tasks = <TaskInfo>[];

    for (final wt in worktrees) {
      if (wt.path.startsWith(tasksDir)) {
        final name = p.basename(wt.path);
        final type = _getTaskType(wt.branch);
        tasks.add(TaskInfo(
          name: name,
          path: wt.path,
          branch: wt.branch,
          type: type,
        ));
      }
    }

    return tasks;
  }

  TaskType _getTaskType(String branch) {
    if (branch.startsWith('feat/')) return TaskType.feat;
    if (branch.startsWith('fix/')) return TaskType.fix;
    if (branch.startsWith('refactor/')) return TaskType.ref;
    return TaskType.feat;
  }

  String _padRight(String text, int width) {
    if (text.length >= width) return text.substring(0, width - 1);
    return text.padRight(width);
  }
}

/// Subcommand for removing a task worktree.
class TaskRemoveCommand extends Command<int> {
  TaskRemoveCommand() {
    argParser
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Force remove even with uncommitted changes.',
        negatable: false,
      )
      ..addFlag(
        'keep-branch',
        help: 'Keep the branch after removing the worktree.',
        negatable: false,
      );
  }

  @override
  String get name => 'remove';

  @override
  List<String> get aliases => ['rm'];

  @override
  String get description => 'Remove a task worktree.';

  @override
  String get invocation => 'flg task remove <name> [--force] [--keep-branch]';

  @override
  Future<int> run() async {
    if (argResults!.rest.isEmpty) {
      ConsoleUtils.error('Please provide a task name.');
      ConsoleUtils.info('Usage: flg task remove <name>');
      return 1;
    }

    final taskName = argResults!.rest.first;
    final force = argResults!['force'] as bool;
    final keepBranch = argResults!['keep-branch'] as bool;

    // Validate task name to prevent path traversal
    final taskNameError = ValidationUtils.validateTaskName(taskName);
    if (taskNameError != null) {
      ConsoleUtils.error(taskNameError);
      return 1;
    }

    final currentDir = Directory.current.path;

    if (!await GitService.isGitRepo(currentDir)) {
      ConsoleUtils.error('Not a git repository.');
      return 1;
    }

    final repoRoot = await GitService.getRepoRoot(currentDir);
    if (repoRoot == null) {
      ConsoleUtils.error('Could not determine repository root.');
      return 1;
    }

    // Find the worktree
    final worktrees = await GitService.worktreeList(repoRoot);
    final projectName = GitService.getProjectName(repoRoot);
    final tasksDir = p.join(p.dirname(repoRoot), '$projectName-tasks');

    WorktreeInfo? targetWorktree;
    for (final wt in worktrees) {
      if (wt.path.startsWith(tasksDir)) {
        final name = p.basename(wt.path);
        if (name == taskName || name.endsWith('-$taskName')) {
          targetWorktree = wt;
          break;
        }
      }
    }

    if (targetWorktree == null) {
      ConsoleUtils.error('Task "$taskName" not found.');
      ConsoleUtils.info('Use "flg task list" to see available tasks.');
      return 1;
    }

    // Check for uncommitted changes
    if (!force && await GitService.hasUncommittedChanges(targetWorktree.path)) {
      ConsoleUtils.error(
        'Task has uncommitted changes. Use --force to remove anyway.',
      );
      return 1;
    }

    // Remove worktree
    final result = await ConsoleUtils.withSpinner(
      'Removing worktree: ${p.basename(targetWorktree.path)}',
      () => GitService.worktreeRemove(
        targetWorktree!.path,
        force: force,
        repoPath: repoRoot,
      ),
    );

    if (result.failed) {
      ConsoleUtils.error('Failed to remove worktree: ${result.stderr}');
      return 1;
    }

    // Prune worktree information
    await GitService.worktreePrune(repoPath: repoRoot);

    // Delete branch unless --keep-branch
    if (!keepBranch && targetWorktree.branch != 'detached') {
      final branchResult = await GitService.deleteBranch(
        repoRoot,
        targetWorktree.branch,
        force: force,
      );
      if (branchResult.success) {
        ConsoleUtils.success('Deleted branch: ${targetWorktree.branch}');
      } else {
        ConsoleUtils.warning(
          'Could not delete branch: ${targetWorktree.branch}',
        );
      }
    }

    ConsoleUtils.success('Task removed: $taskName');
    return 0;
  }
}

/// Subcommand for showing status of all task worktrees.
class TaskStatusCommand extends Command<int> {
  @override
  String get name => 'status';

  @override
  List<String> get aliases => ['st'];

  @override
  String get description => 'Show status of all task worktrees.';

  @override
  Future<int> run() async {
    final currentDir = Directory.current.path;

    if (!await GitService.isGitRepo(currentDir)) {
      ConsoleUtils.error('Not a git repository.');
      return 1;
    }

    final repoRoot = await GitService.getRepoRoot(currentDir);
    if (repoRoot == null) {
      ConsoleUtils.error('Could not determine repository root.');
      return 1;
    }

    final worktrees = await GitService.worktreeList(repoRoot);
    final mainBranch = await GitService.getMainBranch(repoRoot);
    final tasks = await _getTasksWithStatus(worktrees, repoRoot, mainBranch);

    if (tasks.isEmpty) {
      ConsoleUtils.info('No task worktrees found.');
      ConsoleUtils.muted('Create one with: flg task add <name>');
      return 0;
    }

    ConsoleUtils.newLine();
    print('${ConsoleUtils.bold('FLG Tasks')} - ${tasks.length} active');
    ConsoleUtils.newLine();

    for (final task in tasks) {
      final statusStr = _formatStatus(task);
      final changesStr = task.hasChanges ? ConsoleUtils.yellow(' *') : '';

      print(
        '  ${_padRight(task.name, 20)} ${_padRight(task.branch, 25)} $statusStr$changesStr',
      );
    }

    ConsoleUtils.newLine();
    ConsoleUtils.muted('Tip: flg task remove <name> to clean up');
    ConsoleUtils.newLine();

    return 0;
  }

  Future<List<TaskInfo>> _getTasksWithStatus(
    List<WorktreeInfo> worktrees,
    String repoRoot,
    String mainBranch,
  ) async {
    final projectName = GitService.getProjectName(repoRoot);
    final tasksDir = p.join(p.dirname(repoRoot), '$projectName-tasks');
    final tasks = <TaskInfo>[];

    for (final wt in worktrees) {
      if (wt.path.startsWith(tasksDir)) {
        final name = p.basename(wt.path);
        final type = _getTaskType(wt.branch);
        final (ahead, behind) = await GitService.getBranchStatus(
          wt.path,
          mainBranch,
        );
        final hasChanges = await GitService.hasUncommittedChanges(wt.path);

        tasks.add(TaskInfo(
          name: name,
          path: wt.path,
          branch: wt.branch,
          type: type,
          commitsAhead: ahead,
          commitsBehind: behind,
          hasChanges: hasChanges,
        ));
      }
    }

    return tasks;
  }

  TaskType _getTaskType(String branch) {
    if (branch.startsWith('feat/')) return TaskType.feat;
    if (branch.startsWith('fix/')) return TaskType.fix;
    if (branch.startsWith('refactor/')) return TaskType.ref;
    return TaskType.feat;
  }

  String _formatStatus(TaskInfo task) {
    if (task.commitsAhead == 0 && task.commitsBehind == 0) {
      return ConsoleUtils.green('up to date ✓');
    }

    final parts = <String>[];

    if (task.commitsAhead > 0) {
      parts.add('+${task.commitsAhead} commits');
    }

    if (task.commitsBehind > 0) {
      parts.add(ConsoleUtils.yellow('-${task.commitsBehind} behind ⚠'));
    }

    return parts.join(', ');
  }

  String _padRight(String text, int width) {
    if (text.length >= width) return text.substring(0, width - 1);
    return text.padRight(width);
  }
}
