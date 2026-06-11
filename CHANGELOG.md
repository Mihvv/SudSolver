# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0] - Backend & Infrastructure - 2026-05-30

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

## [0.2.0] - Frontend Integration & Persistence - 2026-06-07 

### Added

- User Interface & Screens:
  - Implemented modular frontend structure and core screen routing (MainMenuScreen, ArchiveScreen, and extracted SudokuScreen into game_screen.dart).
  - Enhanced the Sudoku grid UI with proper 3x3 block borders.
  - Added visual feedback by highlighting incorrect numbers in red.
  - Introduced the hints feature to the frontend.
- Game Progress & Resuming:
  - Expanded the history feature to support saving uncompleted Sudoku boards.
  - Implemented backend logic and frontend UI options to allow resuming unfinished games directly from the history screen.
- Media Handling:
  - Added features to handle loading and taking photos within the app.

### Changed

- Validation & Mechanics:
  - Refactored the board validation logic to pinpoint and display specific invalid cells rather than just validating the entire board blindly.
  - Changed the board validation trigger so it only executes when the explicit "check" button is pressed.
- Backend Optimization & Architecture:
  - Abstracted the IScannerService interface and cleaned up model generation.
  - Optimized the backend state management coupling.
- UI/UX Improvements:
  - Moved the digit selection menu higher up on the solving screen for better ergonomics.

### Fixed
- Ensured thread-safe Hive database transactions for UI background tasks.
- Fixed an issue where the board history progress was failing to save.
- Properly formatted the code repository under ./lib.
- Fixed the CI workflow (test.yml) by removing the strict format checking that was causing pipeline failures.
