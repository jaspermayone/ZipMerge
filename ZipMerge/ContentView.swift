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
    @State private var mergeResult: FileComparer.GitMergeResult?
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showingInstructions = false
    
    var body: some View {
        VStack(spacing: 20) {
            setupArea

            if let merge = mergeResult {
                mergeInstructionsView(merge)
            } else {
                emptyStateView
            }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 400)
        .alert("Error", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    private var setupArea: some View {
        VStack(spacing: 12) {
            // Your directory picker
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundColor(.blue)
                VStack(alignment: .leading) {
                    Text("Your Git Project")
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

            if !isGitRepository() && yourDirectory != nil {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Selected directory is not a git repository")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Zip drop zone
            ZipDropZone(zipFile: $zipFile) {
                processZip()
            }

            if isProcessing {
                ProgressView("Processing...")
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "arrow.down.doc.fill")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Drop a zip file to merge")
                .font(.title3)
                .foregroundColor(.secondary)
            Text("First, choose your git project folder above")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func mergeInstructionsView(_ merge: FileComparer.GitMergeResult) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title)
                VStack(alignment: .leading) {
                    Text("Merge Initiated!")
                        .font(.title2)
                        .bold()
                    Text("Branch: \(merge.branchName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            if merge.hasConflicts {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Merge has conflicts - resolve them in your terminal")
                        .foregroundColor(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Next Steps:")
                    .font(.headline)

                Text("Open your terminal in the project directory and use git to selectively merge changes:")
                    .foregroundColor(.secondary)

                codeBlock("cd \(yourDirectory?.path ?? "")")

                Text("1. Review staged changes:")
                    .font(.subheadline)
                codeBlock("git status")

                Text("2. Selectively stage hunks (optional):")
                    .font(.subheadline)
                codeBlock("git add -p")

                Text("3. Commit the merge:")
                    .font(.subheadline)
                codeBlock("git commit")

                Text("4. After committing, come back here and click 'Cleanup' to remove the temporary branch and zip file.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)

            HStack {
                Spacer()
                Button("Cleanup") {
                    cleanupAfterMerge()
                }
                .buttonStyle(.borderedProminent)
            }

            Spacer()
        }
    }

    private func codeBlock(_ text: String) -> some View {
        Text(text)
            .font(.system(.body, design: .monospaced))
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(4)
            .textSelection(.enabled)
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

        guard isGitRepository() else {
            errorMessage = "Selected directory is not a git repository. ZipMerge requires git to work."
            return
        }

        isProcessing = true

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let result = try FileComparer.importZipToGitBranch(zipURL: zip, projectDirectory: yours)

                DispatchQueue.main.async {
                    self.mergeResult = result
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
    
    private func cleanupAfterMerge() {
        guard let merge = mergeResult, let directory = yourDirectory else { return }

        do {
            // Delete the temporary git branch
            try FileComparer.cleanupGitMerge(branchName: merge.branchName, projectDirectory: directory)

            // Delete the zip file
            if let zip = zipFile {
                try? FileManager.default.removeItem(at: zip)
            }

            // Reset state
            mergeResult = nil
            zipFile = nil
        } catch {
            errorMessage = "Failed to cleanup: \(error.localizedDescription)"
        }
    }

    private func isGitRepository() -> Bool {
        guard let directory = yourDirectory else { return false }

        let gitDir = directory.appendingPathComponent(".git")
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: gitDir.path, isDirectory: &isDirectory) && isDirectory.boolValue
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
