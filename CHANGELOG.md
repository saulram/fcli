# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-01-29

### Added

- **`task` command** (alias: `t`) - Manage git worktrees for AI agent workflows
  - `task add <name>` - Create a new task worktree with a dedicated branch
    - `--type` (`-t`): Branch prefix (feat, fix, ref) - default: `feat`
    - `--agent` (`-a`): Setup for AI agent (runs `flutter pub get`, creates `.claude/TASK.md`)
    - `--base` (`-b`): Base branch to create from - default: `main`
    - `--dry-run`: Preview without creating files
  - `task list` (alias: `ls`) - List all active task worktrees
  - `task remove` (alias: `rm`) - Remove a task worktree
    - `--force` (`-f`): Force remove even with uncommitted changes
    - `--keep-branch`: Keep the branch after removing worktree
  - `task status` (alias: `st`) - Show status dashboard with commits ahead/behind

- **GitService** - New service for git operations (worktrees, branches, status)

- **TaskInfo model** - Data model for task worktree information

### Technical Details

- Worktrees are created in `../[project-name]-tasks/` as sibling directories
- Branch naming convention: `{type}/{name}` (e.g., `feat/auth-feature`)
- AI agent setup creates `.claude/TASK.md` template for task context

## [1.0.0] - 2026-01-28

### Added

- **`init` command** - Create new Flutter projects with Clean Architecture
  - Interactive configuration prompts
  - Support for Riverpod (with `@riverpod` annotation), Bloc, and Provider
  - Support for GoRouter and AutoRoute
  - Optional Freezed integration with `sealed class` syntax
  - Optional Dio HTTP client
  - Multi-platform support (Android, iOS, Web, macOS, Windows, Linux)
  - Localization (l10n) support
  - Automatic `build_runner` execution after project creation

- **`setup` command** - Configure flg in existing Flutter projects
  - Detects existing `pubspec.yaml` and extracts project name
  - Adds required dependencies automatically
  - Creates Clean Architecture directory structure
  - Generates core files (exceptions, failures, usecase base, router)
  - Optional initial feature generation
  - Runs `pub get` and `build_runner` automatically

- **`generate` command** with subcommands:
  - `feature` (alias: `f`) - Generate complete feature modules
  - `screen` (alias: `s`) - Generate screen widgets
  - `widget` (alias: `w`) - Generate widgets (stateless, stateful, card, list_tile, form)
  - `provider` (alias: `p`) - Generate providers/notifiers/blocs
  - `usecase` (alias: `u`) - Generate use cases (single or CRUD)
  - `repository` (alias: `r`) - Generate repositories with data sources

- **Core templates**:
  - Exceptions and Failures classes
  - Base UseCase classes with `Either<Failure, T>` pattern
  - App Router configuration (GoRouter or AutoRoute)
  - Main.dart with state management setup

- **Feature templates**:
  - Entity classes with Equatable
  - Repository interfaces
  - Model classes with Freezed `sealed class` syntax
  - Repository implementations
  - Remote data sources (Dio or http)
  - Riverpod notifiers using `@riverpod` annotation with code generation
  - Bloc classes with events and states
  - Provider classes with ChangeNotifier
  - Screen widgets with state management integration
  - Widget templates (card, list tile, form)

- **Configuration**:
  - `flg.json` file for project settings persistence
  - Automatic configuration detection in existing projects

- **Developer experience**:
  - `--dry-run` flag to preview changes without creating files
  - `--verbose` flag for detailed output
  - `--no-color` flag for CI/CD environments
  - Colored console output with progress indicators

### Technical Details

- Written in pure Dart with no Flutter dependency
- Uses absolute package imports (`package:project_name/...`)
- Modern Riverpod with `riverpod_annotation` and code generation
- Modern Freezed with `sealed class` syntax
- Comprehensive test suite (81 tests)
