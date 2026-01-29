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
    
    static func compare(yourDirectory: URL, theirDirectory: URL) throws -> ComparisonResult {
        let fm = FileManager.default
        var files: [ComparedFile] = []
        
        // Get all files from both directories
        let yourFiles = getAllFiles(in: yourDirectory, relativeTo: yourDirectory)
        let theirFiles = getAllFiles(in: theirDirectory, relativeTo: theirDirectory)
        
        let yourPaths = Set(yourFiles.keys)
        let theirPaths = Set(theirFiles.keys)
        
        // Files only in theirs (added)
        for path in theirPaths.subtracting(yourPaths) {
            let content = try? String(contentsOf: theirFiles[path]!, encoding: .utf8)
            files.append(ComparedFile(
                relativePath: path,
                changeType: .added,
                yourContent: nil,
                theirContent: content
            ))
        }
        
        // Files only in yours (deleted from teacher's version)
        for path in yourPaths.subtracting(theirPaths) {
            let content = try? String(contentsOf: yourFiles[path]!, encoding: .utf8)
            files.append(ComparedFile(
                relativePath: path,
                changeType: .deleted,
                yourContent: content,
                theirContent: nil
            ))
        }
        
        // Files in both - check if modified
        for path in yourPaths.intersection(theirPaths) {
            let yourURL = yourFiles[path]!
            let theirURL = theirFiles[path]!
            
            let yourData = try? Data(contentsOf: yourURL)
            let theirData = try? Data(contentsOf: theirURL)
            
            if yourData == theirData {
                files.append(ComparedFile(
                    relativePath: path,
                    changeType: .unchanged
                ))
            } else {
                let yourContent = try? String(contentsOf: yourURL, encoding: .utf8)
                let theirContent = try? String(contentsOf: theirURL, encoding: .utf8)

                // Compute hunks for modified files
                let hunks = computeHunks(yourContent: yourContent ?? "", theirContent: theirContent ?? "")

                files.append(ComparedFile(
                    relativePath: path,
                    changeType: .modified,
                    yourContent: yourContent,
                    theirContent: theirContent,
                    hunks: hunks
                ))
            }
        }
        
        // Sort by path
        files.sort { $0.relativePath < $1.relativePath }
        
        return ComparisonResult(
            files: files,
            yourDirectory: yourDirectory,
            theirDirectory: theirDirectory
        )
    }
    
    private static func getAllFiles(in directory: URL, relativeTo base: URL) -> [String: URL] {
        let fm = FileManager.default
        var result: [String: URL] = [:]
        
        guard let enumerator = fm.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return result
        }
        
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]),
                  resourceValues.isRegularFile == true else {
                continue
            }
            
            let relativePath = fileURL.path.replacingOccurrences(of: base.path + "/", with: "")
            result[relativePath] = fileURL
        }
        
        return result
    }
    
    static func applyChanges(_ comparison: ComparisonResult) throws {
        let fm = FileManager.default
        
        for file in comparison.files {
            guard file.decision != .pending else { continue }
            
            let yourFile = comparison.yourDirectory.appendingPathComponent(file.relativePath)
            let theirFile = comparison.theirDirectory.appendingPathComponent(file.relativePath)
            
            switch (file.changeType, file.decision) {
            case (.added, .takeTheirs):
                // Copy new file from theirs to yours
                let parentDir = yourFile.deletingLastPathComponent()
                try fm.createDirectory(at: parentDir, withIntermediateDirectories: true)
                try fm.copyItem(at: theirFile, to: yourFile)
                
            case (.modified, .takeTheirs):
                // Check if hunks are used
                if !file.hunks.isEmpty {
                    // Apply selected hunks only
                    try applySelectedHunks(file: file, yourFile: yourFile)
                } else {
                    // Replace entire file with theirs
                    try fm.removeItem(at: yourFile)
                    try fm.copyItem(at: theirFile, to: yourFile)
                }
                
            case (.deleted, .takeTheirs):
                // Delete your file (it's not in teacher's version)
                try fm.removeItem(at: yourFile)
                
            case (_, .keepMine):
                // Do nothing, keep your version
                break
                
            default:
                break
            }
        }
    }

    private static func computeHunks(yourContent: String, theirContent: String) -> [DiffHunk] {
        // For now, return empty array - hunk selection can be added later
        // This feature requires a robust diff algorithm which is complex to implement
        return []
    }

    private static func applySelectedHunks(file: ComparedFile, yourFile: URL) throws {
        // This will be implemented when hunk selection UI is ready
        // For now, just replace the entire file
        guard let theirContent = file.theirContent else { return }
        try theirContent.write(to: yourFile, atomically: true, encoding: .utf8)
    }
}
