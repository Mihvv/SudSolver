# SudSolver

> Scan, solve, and track Sudoku puzzles.

---

# Project Goal

SudSolver is a mobile Sudoku application built with Flutter. It allows users to scan physical Sudoku puzzles using the camera, solve them manually or automatically, and keep a synchronized history of completed games. The app supports Google sign-in and cloud sync via Firebase, enabling seamless use across devices.

---

# Features

<!-- TODO: Fill in features -->

---

# Screenshots

<!-- TODO: Add screenshots -->

---

# Technology Stack

## Frontend

| Technology           | Purpose                         |
|----------------------|---------------------------------|
| Flutter / Dart       | Cross-platform mobile framework |
| Flutter Riverpod     | State management                |
| Hive                 | Local persistence               |
| Camera / ImagePicker | Image capture for OCR scanning  |

## Backend / Cloud

| Technology        | Purpose                          |
|-------------------|----------------------------------|
| Firebase Auth     | Google Sign-In authentication    |
| Cloud Firestore   | Remote record storage and sync   |
| HTTP API          | Puzzle fetching and OCR scanning |

---

# Project Structure

```text
lib/
├── backend/
│   ├── logic/
│   ├── models/
│   ├── providers/
│   ├── repositories/
│   └── services/
│       ├── auth/
│       ├── puzzle/
│       └── scanner/
└── frontend/
    ├── screens/
    └── widgets/
```

---

# Screens

<!-- TODO: Fill in screens -->

---

# User Stories

<!-- TODO: Fill in user stories -->

---

# Dependencies

```yaml
flutter_riverpod: ^2.5.1
hive: ^2.2.3
hive_flutter: ^1.1.0
camera: ^0.10.5+9
image_picker: ^1.0.7
firebase_core: ^3.13.1
firebase_auth: ^5.5.3
google_sign_in: ^6.2.2
http: ^1.2.0
http_parser: ^4.0.0
cloud_firestore: ^5.6.12
```

---

# Installation

## Requirements

- Flutter SDK 3.41.9+
- Dart SDK ^3.11.5
- Android SDK (for Android builds)
- Firebase project with `google-services.json`

Check Flutter installation:

```bash
flutter doctor
```

---

# Getting Started

## Clone the Repository

```bash
git clone <repository-url>
cd sudsolver
```

## Install Dependencies

```bash
flutter pub get
```

## Run the Application

```bash
flutter run
```

## Build APK

```bash
flutter build apk
```

## Build App Bundle

```bash
flutter build appbundle
```

---

# Architecture

SudSolver uses a layered architecture with Riverpod for state management and clean separation between backend logic and frontend UI.

Key architectural decisions:

- **`SudokuBoard`** — immutable model; mutations return new instances via `copyWithCell` / `lock`
- **`SudokuSolver`** — backtracking solver operating on raw grids
- **`SudokuValidator`** — stateless validation: move validity, board completeness, invalid cell detection
- **`ISudokuRepository`** — interface implemented by `HiveSudokuRepository` (local) and `FirestoreSudokuRepository` (remote); combined in `SyncedSudokuRepository`
- **`SyncedSudokuRepository`** — writes to local first, fires remote save as fire-and-forget; syncs from cloud on login
- **`SudokuNotifier`** — central game state machine managing scanning, OCR correction, gameplay, hints, timer, and auto-save
- **`HistoryNotifier`** — loads and manages saved game records, reacts to sync status
- **`AuthNotifier`** — wraps `IAuthService`, exposes Google Sign-In and sign-out

---

# CI/CD

| Workflow     | Trigger                        | Action                                              |
|--------------|--------------------------------|-----------------------------------------------------|
| `test.yml`   | Push to `main`, `backend`, `frontend`; PR to `main` | Dart analyze + `flutter test`           |
| `build.yml`  | Push to `main`                 | Build profile APK → Firebase App Distribution      |
| `release.yml`| Push tag `v*`                  | Build release APK (split ABI + full) + AAB → GitHub Release |

---

# Security

Firebase Authentication handles identity. Records in Firestore are stored under the authenticated user's UID (`users/{uid}/sudoku_records`), so each user can only access their own data.

---

# Version

```yaml
version: 0.3.0
```

---

# Team & Roles

| Member        | Role               | Responsibilities                                                                                                 |
|---------------|--------------------|------------------------------------------------------------------------------------------------------------------|
| **WyrwaMichal8**    | Frontend Developer |  |
| **Mihvv**     | Backend Developer  | Data layer architecture (Hive, Firestore, sync), Firebase Auth integration, HTTP services (OCR scanner, puzzle API), Riverpod state management, Sudoku solver & validator logic  |
| **aspencode** | Project Leader     |  |

---

# Repositories

* Project: https://github.com/Mihvv/SudSolver
* Sudoku Scanner API: https://github.com/Mihvv/sudoku-api

---

# Summary

<!-- TODO: Summary -->