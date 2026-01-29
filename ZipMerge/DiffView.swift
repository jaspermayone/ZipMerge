/*
 *
 * © 2026 Jasper Mayone <me@jaspermayone.com>
 * Licensed under the O'Saasy License Agreement (https://osaasy.dev)
 *
 * ZipMerge App - Simple App to help @jsp make it through COMP1050 with a professor who won't use version controll.
 *
 */

import SwiftUI

struct DiffView: View {
    let file: ComparedFile
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(file.relativePath)
                    .font(.headline)
                Spacer()
                changeTypeBadge
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Content based on change type
            switch file.changeType {
            case .added:
                addedFileView
            case .deleted:
                deletedFileView
            case .modified:
                modifiedFileView
            case .unchanged:
                Text("No changes")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private var changeTypeBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: file.icon)
            Text(changeTypeText)
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(changeTypeColor.opacity(0.2))
        .foregroundColor(changeTypeColor)
        .cornerRadius(4)
    }
    
    private var changeTypeText: String {
        switch file.changeType {
        case .added: return "New"
        case .deleted: return "Deleted"
        case .modified: return "Modified"
        case .unchanged: return "Unchanged"
        }
    }
    
    private var changeTypeColor: Color {
        switch file.changeType {
        case .added: return .green
        case .deleted: return .red
        case .modified: return .orange
        case .unchanged: return .gray
        }
    }
    
    private var addedFileView: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("New file from teacher", color: .green)
            ScrollView {
                codeView(file.theirContent ?? "(binary or unreadable)", lineColor: .green.opacity(0.15))
            }
        }
    }
    
    private var deletedFileView: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("File only in your version (not in teacher's zip)", color: .red)
            ScrollView {
                codeView(file.yourContent ?? "(binary or unreadable)", lineColor: .red.opacity(0.15))
            }
        }
    }
    
    private var modifiedFileView: some View {
        HSplitView {
            VStack(alignment: .leading, spacing: 0) {
                sectionHeader("Your version", color: .blue)
                ScrollView {
                    codeView(file.yourContent ?? "(binary or unreadable)", lineColor: nil)
                }
            }
            
            VStack(alignment: .leading, spacing: 0) {
                sectionHeader("Teacher's version", color: .green)
                ScrollView {
                    codeView(file.theirContent ?? "(binary or unreadable)", lineColor: nil)
                }
            }
        }
    }
    
    private func sectionHeader(_ title: String, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .font(.subheadline.bold())
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
    }
    
    private func codeView(_ content: String, lineColor: Color?) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            let lines = content.components(separatedBy: .newlines)
            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                HStack(alignment: .top, spacing: 0) {
                    Text("\(index + 1)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .trailing)
                        .padding(.trailing, 8)
                    
                    Text(line.isEmpty ? " " : line)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                    
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 1)
                .padding(.horizontal, 8)
                .background(lineColor ?? Color.clear)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }
}

#Preview {
    DiffView(file: ComparedFile(
        relativePath: "src/Main.java",
        changeType: .modified,
        yourContent: "public class Main {\n    public static void main(String[] args) {\n        System.out.println(\"Hello\");\n    }\n}",
        theirContent: "public class Main {\n    public static void main(String[] args) {\n        System.out.println(\"Hello World\");\n        // New comment from teacher\n    }\n}"
    ))
}
