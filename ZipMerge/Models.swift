/*
 *
 * © 2026 Jasper Mayone <me@jaspermayone.com>
 * Licensed under the O'Saasy License Agreement (https://osaasy.dev)
 *
 * ZipMerge App - Simple App to help @jsp make it through COMP1050 with a professor who won't use version controll.
 *
 */

import Foundation

enum FileChangeType: Equatable {
    case added      // New file from teacher
    case modified   // File exists in both, content differs
    case deleted    // File in your directory but not in teacher's
    case unchanged  // Identical
}

enum MergeDecision {
    case pending
    case keepMine
    case takeTheirs
}

struct DiffHunk: Identifiable, Equatable, Hashable {
    let id = UUID()
    let yourStartLine: Int
    let yourLineCount: Int
    let theirStartLine: Int
    let theirLineCount: Int
    let lines: [DiffLine]
    var isSelected: Bool = true  // Default to selected

    var header: String {
        "@@ -\(yourStartLine),\(yourLineCount) +\(theirStartLine),\(theirLineCount) @@"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct DiffLine: Equatable, Hashable {
    enum LineType: Equatable {
        case context    // Unchanged line
        case addition   // Line added in their version
        case deletion   // Line deleted in their version
    }

    let type: LineType
    let content: String
    let yourLineNumber: Int?
    let theirLineNumber: Int?
}

struct ComparedFile: Identifiable, Equatable, Hashable {
	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}

	let id = UUID()
    let relativePath: String
    let changeType: FileChangeType
    var decision: MergeDecision = .pending

    // For modified files, store both versions
    var yourContent: String?
    var theirContent: String?

    // For granular hunk selection on modified files
    var hunks: [DiffHunk] = []
    
    var fileName: String {
        (relativePath as NSString).lastPathComponent
    }
    
    var icon: String {
        switch changeType {
        case .added: return "plus.circle.fill"
        case .modified: return "pencil.circle.fill"
        case .deleted: return "minus.circle.fill"
        case .unchanged: return "checkmark.circle.fill"
        }
    }
    
    var color: String {
        switch changeType {
        case .added: return "green"
        case .modified: return "orange"
        case .deleted: return "red"
        case .unchanged: return "gray"
        }
    }
}

struct ComparisonResult {
    var files: [ComparedFile]
    let yourDirectory: URL
    let theirDirectory: URL
    
    var pendingCount: Int {
        files.filter { $0.decision == .pending && $0.changeType != .unchanged }.count
    }
    
    var changedFiles: [ComparedFile] {
        files.filter { $0.changeType != .unchanged }
    }
}
