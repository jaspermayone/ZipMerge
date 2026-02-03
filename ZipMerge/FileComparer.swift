/*
 *
 * © 2026 Jasper Mayone <me@jaspermayone.com>
 * Licensed under the O'Saasy License Agreement (https://osaasy.dev)
 *
 * ZipMerge App - Simple App to help @jsp make it through COMP1050 with a professor who won't use version controll.
 *
 */

import Foundation
import Compression

class FileComparer {

    struct GitMergeResult {
        let branchName: String
        let originalBranch: String
        let hasConflicts: Bool
    }

    static func importZipToGitBranch(zipURL: URL, projectDirectory: URL) throws -> GitMergeResult {
        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let branchName = "zip-import-\(timestamp)"

        // Get current branch name
        let originalBranch = try runGitCommand(["branch", "--show-current"], at: projectDirectory).trimmingCharacters(in: .whitespacesAndNewlines)

        // Create temp directory for extraction
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // Ensure temp directory is cleaned up
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        do {
            // Extract zip to temp directory
            try extractZip(at: zipURL, to: tempDir)

            // Find the actual root (in case zip has a wrapper folder)
            let extractedRoot = findRootDirectory(in: tempDir)

            // Create and checkout new branch
            try runGitCommand(["checkout", "-b", branchName], at: projectDirectory)

            // Copy extracted files to project directory
            try copyContents(from: extractedRoot, to: projectDirectory)

            // Stage all changes
            _ = try runGitCommand(["add", "-A"], at: projectDirectory)

            // Commit the changes
            let commitMessage = "Import from zip: \(zipURL.lastPathComponent)"
            _ = try runGitCommand(["commit", "-m", commitMessage], at: projectDirectory)

            // Switch back to original branch
            _ = try runGitCommand(["checkout", originalBranch], at: projectDirectory)

            // Initiate merge without committing (allows selective staging)
            let mergeOutput = try? runGitCommand(["merge", "--no-commit", "--no-ff", branchName], at: projectDirectory)
            let hasConflicts = mergeOutput?.contains("CONFLICT") ?? false

            // Unstage all changes so user can selectively stage with git add -p
            _ = try? runGitCommand(["reset"], at: projectDirectory)

            // Write a cleaner commit message template
            let cleanMessage = "Merge changes from \(zipURL.deletingPathExtension().lastPathComponent)"
            let mergeMessagePath = projectDirectory.appendingPathComponent(".git/MERGE_MSG")
            try? cleanMessage.write(to: mergeMessagePath, atomically: true, encoding: .utf8)

            return GitMergeResult(
                branchName: branchName,
                originalBranch: originalBranch,
                hasConflicts: hasConflicts
            )
        } catch {
            // Cleanup: try to switch back to original branch if something went wrong
            _ = try? runGitCommand(["checkout", originalBranch], at: projectDirectory)
            _ = try? runGitCommand(["branch", "-D", branchName], at: projectDirectory)
            throw error
        }
    }

    static func cleanupGitMerge(branchName: String, projectDirectory: URL) throws {
        // Check if a merge is in progress by looking for MERGE_HEAD
        let mergeHeadPath = projectDirectory.appendingPathComponent(".git/MERGE_HEAD")
        if FileManager.default.fileExists(atPath: mergeHeadPath.path) {
            // Abort the merge to clean up merge state
            _ = try? runGitCommand(["merge", "--abort"], at: projectDirectory)
        }

        // Discard any uncommitted changes
        _ = try? runGitCommand(["reset", "--hard"], at: projectDirectory)

        // Clean any untracked files (but preserve ignored files)
        _ = try? runGitCommand(["clean", "-fd"], at: projectDirectory)

        // Delete the temporary branch
        _ = try runGitCommand(["branch", "-D", branchName], at: projectDirectory)
    }

    private static func runGitCommand(_ arguments: [String], at directory: URL) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.currentDirectoryURL = directory
        process.arguments = arguments

        // Set up environment with full PATH so git hooks can find git-lfs and other tools
        var environment = ProcessInfo.processInfo.environment
        if let userPath = environment["PATH"] {
            // Ensure common git-lfs installation paths are included
            let additionalPaths = [
                "/opt/homebrew/bin",
                "/usr/local/bin",
                "/etc/profiles/per-user/\(NSUserName())/bin"
            ]
            let pathComponents = userPath.split(separator: ":").map(String.init)
            let allPaths = (additionalPaths + pathComponents).joined(separator: ":")
            environment["PATH"] = allPaths
        }
        process.environment = environment

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outputData, encoding: .utf8) ?? ""

        if process.terminationStatus != 0 {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorOutput = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "ZipMerge", code: Int(process.terminationStatus),
                         userInfo: [NSLocalizedDescriptionKey: "Git command failed: \(errorOutput)"])
        }

        return output
    }

    private static func copyContents(from source: URL, to destination: URL) throws {
        let fm = FileManager.default
        let contents = try fm.contentsOfDirectory(at: source, includingPropertiesForKeys: nil)

        for item in contents {
            let itemName = item.lastPathComponent

            // Skip .git directory, .DS_Store, and __MACOSX
            if itemName == ".git" || itemName == ".DS_Store" || itemName == "__MACOSX" {
                continue
            }

            let destPath = destination.appendingPathComponent(itemName)

            // Remove existing item if it exists
            if fm.fileExists(atPath: destPath.path) {
                try fm.removeItem(at: destPath)
            }

            // Copy the item (including hidden files for Eclipse projects)
            try fm.copyItem(at: item, to: destPath)
        }
    }

    static func extractZip(at zipURL: URL, to destination: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-o", zipURL.path, "-d", destination.path]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "ZipMerge", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to extract zip: \(output)"])
        }
    }
    
    static func findRootDirectory(in directory: URL) -> URL {
        // Sometimes zips contain a single root folder, we want to get inside it
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isDirectoryKey]) else {
            return directory
        }
        
        let nonHidden = contents.filter { !$0.lastPathComponent.hasPrefix(".") && !$0.lastPathComponent.hasPrefix("__") }
        
        if nonHidden.count == 1,
           let first = nonHidden.first,
           (try? first.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
            return first
        }
        
        return directory
    }
}
