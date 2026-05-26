# AGENTS.md — InviScan

## Project Overview

**InviScan** is a Flutter desktop/mobile application for subdomain reconnaissance used in penetration testing and bug bounty hunting. It provides a unified GUI over several open-source CLI security tools, orchestrates them sequentially, and persists results to disk.

- Language: Dart 3.7.2+
- Framework: Flutter 3.7.2+
- Platforms: Linux, macOS, Windows, Android, iOS, Web
- State management: Provider (ChangeNotifier)
- Persistence: SharedPreferences (scan history) + file system (scan artifacts)
- No backend or database — fully client-side

## Architecture

The project follows a strict layered architecture:

```
screens/ → viewmodels/ → services/ → repositories/ → models/
```

- **models/** — Plain Dart classes with JSON serialization (e.g. `ScanRecord`)
- **repositories/** — SharedPreferences-backed persistence (`ScanHistoryRepository`)
- **services/** — Business logic; one file per external tool under `services/scan/`
- **viewmodels/** — ChangeNotifier classes consumed by widgets (`ScanViewModel`)
- **screens/** — UI screens; receive state from viewmodels via `context.watch`
- **widgets/** — Reusable UI components
- **utils/** — Pure helper functions (binary resolution, juicy target detection, log formatting)

## Entry Point

`lib/main.dart` — initializes Flutter, registers `ScanViewModel` in a `MultiProvider`, and launches `HomeScreen`.

## Scan Execution Flow

```
HomeScreen (domain input)
  → ScanScreen
    → ScanViewModel.scan()
      → ScanService.scanDomainWithProgress()
          ├── runSubfinder()       passive subdomain discovery
          ├── runAssetfinder()     public source scraping
          ├── runCrtsh()           SSL certificate transparency (HTTP)
          ├── runFfuf()            active fuzzing with wordlist
          ├── runHttprobe()        HTTP liveness verification
          └── runGowitness()       screenshot capture
      → saveResults()             write artifacts to ~/inviscan/<timestamp>/
      → ScanHistoryRepository.append()
  → ResultsScreen
```

Each tool wrapper in `services/scan/` uses `Process.start()` with concurrent stdout/stderr draining to avoid pipe deadlocks.

## External Tools

InviScan shells out to these binaries (bundled under `binaries/linux/` or resolved from PATH):

| Tool | Purpose |
|---|---|
| subfinder | Passive subdomain discovery |
| assetfinder | Public source scraping |
| ffuf | Active subdomain fuzzing |
| httprobe | HTTP liveness check |
| gowitness | Screenshot capture |

crt.sh is queried via Dart's `HttpClient` (no local binary).

Binary resolution is handled in `lib/utils/binaries.dart`: bundled paths take precedence over PATH.

## Persistence

**Scan history** (`ScanRecord` list) is stored as JSON in SharedPreferences.

**Scan artifacts** are written to `~/inviscan/<timestamp>/`:
- `subdominios_unicos.txt` — all unique subdomains
- `subdominios_unicos_ativos.txt` — live subdomains
- `juicy_targets.txt` — high-value targets (matched by 101-keyword regex in `utils/juicy_targets.dart`)
- `gowitness/` — screenshots
- `gowitness_targets.txt` — URL list fed to gowitness

## Settings & Customization

Tool commands are stored in SharedPreferences and editable in `SettingsScreen`. Commands support variable substitution:
- `DOMAIN` — target domain
- `FUZZ` — ffuf wordlist path placeholder

## Testing

```bash
flutter test
```

Tests live in `test/` and mirror the `lib/` structure. Coverage includes models, repositories, utils, and viewmodels. Widget tests are in `widget_test.dart`.

Allowed test/lint commands per `.claude/settings.local.json`:
- `flutter test`
- `flutter analyze`
- `flutter pub`

## Key Conventions

- All UI text and comments are in Portuguese (pt-BR).
- `Set<String>` is used everywhere for O(1) deduplication of subdomains.
- `runInShell: false` on all `Process.start()` calls (security).
- `Future.wait([stdoutDone, stderrDone])` pattern on every process to prevent hangs.
- Callbacks (`onLog`, `onProgress`, `onEnd`) are passed into `ScanService` for real-time UI updates — do not add `notifyListeners()` calls inside service/scan layers.
- Do not add a database dependency; the SharedPreferences + filesystem strategy is intentional.

## Wordlist

`lib/wordlists/ffuf/wordlist.txt` contains 114,442 entries and is bundled with the app. Do not replace or truncate it without explicit instruction.

## File Naming

Follow the existing `snake_case.dart` convention for all new Dart files.
