# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ZipMerge is a macOS SwiftUI application that compares a local project directory with a teacher's submitted zip file. It's designed to help students merge changes from assignments when version control isn't used by instructors.

## Building and Running

```bash
# Build the project
xcodebuild -project ZipMerge.xcodeproj -scheme ZipMerge build

# Run the app (after building in Xcode)
open ZipMerge.xcodeproj
# Then press Cmd+R in Xcode to run
```

The project uses Swift 5.0 and requires macOS with SwiftUI support.

## Code Signing and Installation

The project is configured with:
- **Bundle Identifier**: com.singlefeather.ZipMerge
- **Development Team**: M67B42LX8D
- **Code Sign Style**: Automatic
- **Code Sign Identity**: Currently ad-hoc (for local development)

### Building for Local Development

```bash
# Build the project
xcodebuild -project ZipMerge.xcodeproj -scheme ZipMerge -configuration Release clean build

# The built app will be in:
# ./build/Release/ZipMerge.app

# Copy to Applications folder (optional)
cp -r build/Release/ZipMerge.app /Applications/
```

### Release Process

**Use the local release script for simplicity:**

```bash
./release.sh v1.0.0
```

This automated script handles everything:
1. Builds with Developer ID signing
2. Notarizes with Apple
3. Creates GitHub release with signed .zip
4. Calculates SHA256 hash
5. Updates Homebrew cask automatically
6. Commits and pushes cask update

**Prerequisites:**
- `gh` CLI installed and authenticated
- Developer ID Application certificate in Keychain
- Apple ID app-specific password (prompted during script)

The script is fully automated and requires no manual steps. See RELEASING.md for details.

### Distributing via Homebrew

The Homebrew cask is located at `/Users/jsp/dev/projects/homebrew-tap/Casks/zipmerge.rb`.

After each release, update the SHA256 hash in the cask file with the value from the release notes.

**Users can install via:**
```bash
brew tap jaspermayone/tap
brew install --cask zipmerge
```

### Manual Distribution (Without CI)

If you need to build manually:

```bash
# Build with Developer ID signing
xcodebuild -project ZipMerge.xcodeproj -scheme ZipMerge -configuration Release \
  CODE_SIGN_IDENTITY="Developer ID Application" clean build

# Notarize
xcrun notarytool submit build/Release/ZipMerge.app.zip \
  --apple-id your-email@example.com \
  --team-id M67B42LX8D \
  --password app-specific-password \
  --wait

# Staple and package
xcrun stapler staple build/Release/ZipMerge.app
cd build/Release && zip -r ZipMerge.zip ZipMerge.app
```

## Architecture

### Core Components

**Models.swift** - Defines the data model:
- `FileChangeType`: Enum for tracking file states (added, modified, deleted, unchanged)
- `MergeDecision`: User decision per file (keepMine, takeTheirs, pending)
- `ComparedFile`: Represents a single file comparison with diff hunks
- `DiffHunk` and `DiffLine`: Structures for granular diff display (not yet fully implemented)
- `ComparisonResult`: Contains all compared files and directories

**FileComparer.swift** - File operations and comparison logic:
- `extractZip()`: Uses system `unzip` command to extract archives
- `findRootDirectory()`: Handles zips with wrapper folders
- `compare()`: Main comparison engine that walks both directory trees and categorizes changes
- `applyChanges()`: Applies user merge decisions to the local directory
- `computeHunks()`: Placeholder for future hunk-level merging (currently returns empty array)

**ContentView.swift** - Main UI orchestration:
- Left panel: Directory picker, zip drop zone, and file list
- Right panel: Diff view for selected file
- State management for comparison results and merge decisions
- Git integration: Detects git repos and offers commit creation after merge
- File cleanup: Removes temp directories and zip files after successful merge

**DiffView.swift** - File diff visualization:
- Side-by-side view for modified files
- Single pane for added/deleted files with color-coded backgrounds
- Line-by-line display with monospaced font

### Data Flow

1. User selects project directory and drops teacher's zip file
2. `FileComparer.extractZip()` extracts to temp directory
3. `FileComparer.compare()` walks both trees and generates `ComparisonResult`
4. UI displays changed files with color-coded icons
5. User reviews diffs and makes keepMine/takeTheirs decisions per file
6. `FileComparer.applyChanges()` applies decisions
7. If git repo detected, optionally creates commit
8. Cleanup removes temp files and zip

### Important Implementation Details

- Zip extraction uses system `/usr/bin/unzip` command via Process
- Comparison is byte-level for binaries, line-level diffs for text (when viewing)
- Temp directories are created in system temp folder with UUID names
- Git commits use `/usr/bin/git` directly (not libgit2 or similar)
- All file operations happen on background queue, UI updates on main thread

## Known Limitations

- Hunk-level merging (`computeHunks()` and `applySelectedHunks()`) is stubbed but not implemented
- Currently only supports whole-file merge decisions
- No conflict resolution UI for line-level merging
- Binary files show as "(binary or unreadable)" in diff view
