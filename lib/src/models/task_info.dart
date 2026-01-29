/// Task type for branch prefix.
enum TaskType {
  feat('feat', 'feature'),
  fix('fix', 'bugfix'),
  ref('refactor', 'refactor');

  const TaskType(this.branchPrefix, this.label);

  final String branchPrefix;
  final String label;

  static TaskType fromString(String value) {
    return switch (value.toLowerCase()) {
      'feat' || 'feature' => TaskType.feat,
      'fix' || 'bugfix' => TaskType.fix,
      'ref' || 'refactor' => TaskType.ref,
      _ => TaskType.feat,
    };
  }
}

/// Information about a task worktree.
class TaskInfo {
  const TaskInfo({
    required this.name,
    required this.path,
    required this.branch,
    required this.type,
    this.commitsAhead = 0,
    this.commitsBehind = 0,
    this.hasChanges = false,
  });

  final String name;
  final String path;
  final String branch;
  final TaskType type;
  final int commitsAhead;
  final int commitsBehind;
  final bool hasChanges;

  /// Whether the task is up to date with the base branch.
  bool get isUpToDate => commitsBehind == 0;

  /// Whether the task has commits.
  bool get hasCommits => commitsAhead > 0;

  /// Creates a copy with updated fields.
  TaskInfo copyWith({
    String? name,
    String? path,
    String? branch,
    TaskType? type,
    int? commitsAhead,
    int? commitsBehind,
    bool? hasChanges,
  }) {
    return TaskInfo(
      name: name ?? this.name,
      path: path ?? this.path,
      branch: branch ?? this.branch,
      type: type ?? this.type,
      commitsAhead: commitsAhead ?? this.commitsAhead,
      commitsBehind: commitsBehind ?? this.commitsBehind,
      hasChanges: hasChanges ?? this.hasChanges,
    );
  }

  @override
  String toString() => 'TaskInfo(name: $name, branch: $branch, path: $path)';
}
