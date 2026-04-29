# Repository Guidelines

## Project Structure & Module Organization

This repository is a Dart CLI package for `flg`, a Flutter Clean Architecture generator. CLI entrypoints live in `bin/`: `flg.dart` for the user command and `flg_mcp.dart` for the MCP server. Public exports are in `lib/flg.dart`; implementation code is under `lib/src/`, grouped by concern: `commands/`, `generators/`, `templates/`, `config/`, `services/`, `utils/`, and `models/`. Tests are split into `test/unit/` for focused utilities/config/template checks and `test/integration/` for command-level generation flows. Documentation and release notes live in `README.md` and `CHANGELOG.md`.

## Build, Test, and Development Commands

- `dart pub get`: install package dependencies.
- `dart run bin/flg.dart --help`: run the CLI locally without global activation.
- `dart run bin/flg_mcp.dart`: start the MCP server locally for manual checks.
- `dart analyze`: run static analysis using `analysis_options.yaml`.
- `dart format .`: format Dart files before committing.
- `dart test`: run all unit and integration tests.
- `dart pub global activate --source path .`: install the local checkout as the `flg` executable.

## Coding Style & Naming Conventions

Follow the Dart lints configured in `analysis_options.yaml`, which keeps strict casts, strict inference, strict raw types, and package/file naming checks. Use two-space indentation and `package:flg/...` imports instead of relative `lib` imports. File names should use `snake_case.dart`; classes and enums use `PascalCase`; methods, variables, and parameters use `lowerCamelCase`. Keep generator templates in `lib/src/templates/` and generator orchestration in `lib/src/generators/`.

## Testing Guidelines

The project uses `package:test`. Name test files with the `_test.dart` suffix and group assertions by class, command, or behavior, for example `group('StringUtils', ...)`. Add unit tests for utilities, config parsing, and templates; add integration tests when command output or generated project structure changes. Run `dart test` and `dart analyze` before opening a PR.

## Commit & Pull Request Guidelines

Recent history follows Conventional Commit style, such as `feat(security): ...`, `docs: ...`, and `chore(release): ...`. Use a short imperative subject and an optional scope when useful. Pull requests should describe the change, explain user-visible behavior, link relevant issues, and include test results. For generator output changes, include before/after examples or screenshots where they clarify the impact.

## Agent-Specific Notes

Do not edit generated sample output by hand unless the task explicitly targets fixtures. Preserve the CLI/MCP split between `bin/flg.dart` and `bin/flg_mcp.dart`, and keep security-sensitive validation close to command or service boundaries.
