/*
 *
 * © 2026 Jasper Mayone <me@jaspermayone.com>
 * Licensed under the O'Saasy License Agreement (https://osaasy.dev)
 *
 * ZipMerge App - Simple App to help @jsp make it through COMP1050 with a professor who won't use version controll.
 *
 */

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var yourDirectory: URL?
    @State private var zipFile: URL?
    @State private var comparison: ComparisonResult?
    @State private var selectedFile: ComparedFile?
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showingSuccess = false
    @State private var tempDirectory: URL?
    @State private var showingGitCommit = false
    @State private var commitMessage = ""
    
    var body: some View {
        HSplitView {
            // Left panel - file list
            VStack(spacing: 0) {
                setupArea
                
                if let comparison = comparison {
                    fileListView(comparison)
                } else {
                    emptyStateView
                }
            }
            .frame(minWidth: 300, idealWidth: 350)
            
            // Right panel - diff view
            if let file = selectedFile, file.changeType == .modified || file.changeType == .added || file.changeType == .deleted {
                DiffView(file: file)
            } else {
                VStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Select a file to view changes")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .alert("Error", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .alert("Success", isPresented: $showingSuccess) {
            Button("OK") {
                if isGitRepository() {
                    showingSuccess = false
                    showingGitCommit = true
                } else {
                    cleanupAfterMerge()
                }
            }
        } message: {
            Text("Changes applied successfully!")
        }
        .alert("Create Git Commit", isPresented: $showingGitCommit) {
            TextField("Commit message", text: $commitMessage)
            Button("Commit") {
                createGitCommit()
                cleanupAfterMerge()
            }
            Button("Skip") {
                cleanupAfterMerge()
            }
        } message: {
            Text("Would you like to create a git commit for these changes?")
        }
    }
    
    private var setupArea: some View {
        VStack(spacing: 12) {
            // Your directory picker
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundColor(.blue)
                VStack(alignment: .leading) {
                    Text("Your Project")
                        .font(.headline)
                    Text(yourDirectory?.lastPathComponent ?? "Not selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Choose...") {
                    chooseYourDirectory()
                }
            }
            .padding(10)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            // Zip drop zone
            ZipDropZone(zipFile: $zipFile) {
                processZip()
            }
            
            if isProcessing {
                ProgressView("Processing...")
            }
            
            if let comparison = comparison, comparison.changedFiles.count > 0 {
                HStack {
                    Text("\(comparison.pendingCount) pending")
                        .foregroundColor(.orange)
                    Spacer()
                    Button("Apply Changes") {
                        applyChanges()
                    }
                    .disabled(comparison.pendingCount > 0)
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "arrow.down.doc.fill")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Drop a zip file to compare")
                .font(.title3)
                .foregroundColor(.secondary)
            Text("First, choose your project folder above")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    private func fileListView(_ comparison: ComparisonResult) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Changed Files")
                .font(.headline)
                .padding(.horizontal)
                .padding(.vertical, 8)
            
            Divider()
            
            if comparison.changedFiles.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    Text("No changes detected")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List(comparison.changedFiles, selection: $selectedFile) { file in
                    FileRowView(file: binding(for: file))
                        .tag(file)
                }
                .listStyle(.inset)
            }
        }
    }
    
    private func binding(for file: ComparedFile) -> Binding<ComparedFile> {
        Binding(
            get: { 
                comparison?.files.first { $0.id == file.id } ?? file
            },
            set: { newValue in
                if let index = comparison?.files.firstIndex(where: { $0.id == file.id }) {
                    comparison?.files[index] = newValue
                }
            }
        )
    }
    
    private func chooseYourDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose your project folder"
        
        if panel.runModal() == .OK {
            yourDirectory = panel.url
        }
    }
    
    private func processZip() {
        guard let zip = zipFile, let yours = yourDirectory else {
            errorMessage = "Please select both your project folder and a zip file"
            return
        }

        isProcessing = true

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Create temp directory for extraction
                let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
                try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

                // Extract zip
                try FileComparer.extractZip(at: zip, to: tempDir)

                // Find the actual root (in case zip has a wrapper folder)
                let theirRoot = FileComparer.findRootDirectory(in: tempDir)

                // Compare
                let result = try FileComparer.compare(yourDirectory: yours, theirDirectory: theirRoot)

                DispatchQueue.main.async {
                    self.tempDirectory = tempDir
                    self.comparison = result
                    self.isProcessing = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isProcessing = false
                }
            }
        }
    }
    
    private func applyChanges() {
        guard let comparison = comparison else { return }

        do {
            try FileComparer.applyChanges(comparison)
            showingSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func cleanupAfterMerge() {
        // Clean up temp directory
        if let tempDir = tempDirectory {
            try? FileManager.default.removeItem(at: tempDir)
            tempDirectory = nil
        }

        // Delete the zip file
        if let zip = zipFile {
            try? FileManager.default.removeItem(at: zip)
        }

        // Reset state
        comparison = nil
        zipFile = nil
        commitMessage = ""
    }

    private func isGitRepository() -> Bool {
        guard let directory = yourDirectory else { return false }

        let gitDir = directory.appendingPathComponent(".git")
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: gitDir.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }

    private func createGitCommit() {
        guard let directory = yourDirectory else { return }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.currentDirectoryURL = directory
        process.arguments = ["commit", "-am", commitMessage.isEmpty ? "[ZipMerge Auto Merge]" : commitMessage]

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            errorMessage = "Failed to create git commit: \(error.localizedDescription)"
        }
    }
}

struct FileRowView: View {
    @Binding var file: ComparedFile
    
    var body: some View {
        HStack {
            Image(systemName: file.icon)
                .foregroundColor(colorForType(file.changeType))
            
            VStack(alignment: .leading) {
                Text(file.fileName)
                    .lineLimit(1)
                Text(file.relativePath)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if file.changeType != .unchanged {
                decisionButtons
            }
        }
        .padding(.vertical, 4)
    }
    
    private var decisionButtons: some View {
        HStack(spacing: 4) {
            Button {
                file.decision = .keepMine
            } label: {
                Image(systemName: "person.fill")
                    .foregroundColor(file.decision == .keepMine ? .white : .blue)
            }
            .buttonStyle(.bordered)
            .tint(file.decision == .keepMine ? .blue : nil)
            .help("Keep your version")
            
            Button {
                file.decision = .takeTheirs
            } label: {
                Image(systemName: "graduationcap.fill")
                    .foregroundColor(file.decision == .takeTheirs ? .white : .green)
            }
            .buttonStyle(.bordered)
            .tint(file.decision == .takeTheirs ? .green : nil)
            .help("Take teacher's version")
        }
    }
    
    private func colorForType(_ type: FileChangeType) -> Color {
        switch type {
        case .added: return .green
        case .modified: return .orange
        case .deleted: return .red
        case .unchanged: return .gray
        }
    }
}

struct ZipDropZone: View {
    @Binding var zipFile: URL?
    var onDrop: () -> Void
    
    @State private var isTargeted = false
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.zipper")
                .font(.system(size: 24))
            if let zip = zipFile {
                Text(zip.lastPathComponent)
                    .lineLimit(1)
            } else {
                Text("Drop zip here")
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                .foregroundColor(isTargeted ? .blue : .secondary)
        )
        .background(isTargeted ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            guard let provider = providers.first else { return false }
            
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, error in
                guard let data = data as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil),
                      url.pathExtension.lowercased() == "zip" else {
                    return
                }
                
                DispatchQueue.main.async {
                    zipFile = url
                    onDrop()
                }
            }
            return true
        }
        .onTapGesture {
            chooseZip()
        }
    }
    
    private func chooseZip() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [UTType.zip]
        panel.message = "Choose teacher's zip file"
        
        if panel.runModal() == .OK, let url = panel.url {
            zipFile = url
            onDrop()
        }
    }
}

#Preview {
    ContentView()
}
