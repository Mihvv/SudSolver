# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - Backend & Infrastructure - 2026-05-30

### Added
- Initialized Flutter project architecture.
- Implemented `SudokuBoard` and `SudokuRecord` data models with Hive adapters.
- Created `SudokuValidator` for real-time move validation.
- Implemented `SudokuSolver` using backtracking algorithm.
- Configured application state management using Riverpod (`SudokuNotifier`).
- Implemented `SudokuRepository` utilizing Hive local database for game history.
- Wrote comprehensive unit test suite for all backend components.

### CI/CD & DevOps
- Configured GitHub Actions workflow for static analysis (`flutter analyze`) and automated testing (`flutter test`).
- Integrated Firebase App Distribution for automated APK deployment.
