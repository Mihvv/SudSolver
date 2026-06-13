# Changelog

All notable changes to this project will be documented in this file.

## [0.3.0] - 2026-06-12

### Added
- **Authentication & User Accounts (Backend):** Implemented full user account support and authorization leveraging Firebase Auth (`firebase_auth_service.dart`, `auth_notifier.dart`). Configured Cloud Firestore database infrastructure for storing user profile data.
- **User Interface (Frontend):** Added a dedicated user profile screen (`profile_screen.dart`) and introduced an `AuthGate` component to conditionally route users based on their login state.
- **Random Board Generation:** Integrated an external HTTP service (`http_puzzle_service.dart`) to fetch random Sudoku puzzles from a remote API and added a dedicated trigger button to the user interface.
- **OCR Scanner Integration:** Connected the frontend camera and preview layers (`camera_screen.dart`, `edit_photo_screen.dart`) with the backend OCR engine network service (`http_scanner_service.dart`), enabling physical boards to be uploaded and parsed via the OpenCV-based backend.
- **Firebase Configuration:** Added core Firebase configuration files (`firebase.json`, `firebase_options.dart`) to the project structure.

### Changed
- **Dependencies Upgrade:** Updated `pubspec.yaml` with the necessary packages to support the Firebase ecosystem (`firebase_core`, `firebase_auth`, `cloud_firestore`).
- **Authentication Flow:** Configured Firebase initialization to be simplified and made authentication optional during development to streamline local testing environments.

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

