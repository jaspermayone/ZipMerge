# ZipMerge

A macOS app that helps students merge changes from teacher-provided zip files when version control isn't available.

## The Problem

You're working on a programming assignment. Your professor gives you a starter zip file. You make changes. Then the professor releases an updated zip with fixes or new requirements. Now you need to figure out what changed and merge those updates into your modified code - without losing your work.

**ZipMerge solves this.**

## What It Does

ZipMerge compares your local project directory with a teacher's zip file and shows you:

- 🟢 **New files** from the teacher
- 🟠 **Modified files** with side-by-side diffs
- 🔴 **Deleted files** that are in your version but not theirs
- ⚪ **Unchanged files** (shown but ignored)

For each file, you choose:
- **Keep Mine** - Ignore the teacher's version
- **Take Theirs** - Replace with the teacher's version

After reviewing all changes, apply them with one click. If your project is a git repo, ZipMerge can automatically create a commit for you.

## Installation

### Via Homebrew (Recommended)

```bash
brew tap jaspermayone/tap
brew install --cask zipmerge
```

### Manual Installation

1. Download `ZipMerge.zip` from the [latest release](https://github.com/jaspermayone/ZipMerge/releases/latest)
2. Unzip and move `ZipMerge.app` to `/Applications`
3. Open the app (right-click → Open on first launch)

## Usage

1. **Select your project directory** - Click "Choose Directory" or drag it in
2. **Drop the teacher's zip file** - Drag the `.zip` file onto the drop zone
3. **Review changes** - Click through each modified file and see the diffs
4. **Make decisions** - For each file, choose "Keep Mine" or "Take Theirs"
5. **Apply changes** - Click "Apply Changes" to merge
6. **Commit (optional)** - If it's a git repo, create a commit with the changes

## Features

- **Side-by-side diff viewer** for modified files
- **File-by-file merge decisions** - no forced overwrites
- **Git integration** - auto-detect repos and offer to commit
- **Smart zip handling** - handles zips with wrapper folders
- **Automatic cleanup** - removes temp files after merge

## Development

### Building from Source

```bash
# Clone the repository
git clone https://github.com/jaspermayone/ZipMerge.git
cd ZipMerge

# Open in Xcode
open ZipMerge.xcodeproj

# Or build from command line
xcodebuild -project ZipMerge.xcodeproj -scheme ZipMerge -configuration Release build
```

### Project Structure

- `ZipMerge/Models.swift` - Data models for file comparisons
- `ZipMerge/FileComparer.swift` - Core comparison and merge logic
- `ZipMerge/ContentView.swift` - Main UI
- `ZipMerge/DiffView.swift` - Diff visualization

See [CLAUDE.md](CLAUDE.md) for detailed architecture documentation.

### Creating a Release

See [RELEASING.md](RELEASING.md) for the release process.

## Known Limitations

- Currently supports whole-file merge decisions only (no line-by-line merging)
- Binary files show as "(binary or unreadable)" in diff view
- Requires macOS with SwiftUI support

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

Licensed under the [O'Saasy License Agreement](LICENSE.md) - essentially MIT with a non-compete clause for SaaS offerings.

## Author

Built by [Jasper Mayone](https://jaspermayone.com) to survive COMP1050 with a professor who won't use version control.

## Acknowledgments

Sometimes the best tools come from personal frustration. This is one of those times.
