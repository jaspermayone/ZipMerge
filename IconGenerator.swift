/*
 *
 * © 2026 Jasper Mayone <me@jaspermayone.com>
 * Licensed under the O'Saasy License Agreement (https://osaasy.dev/")
 *
 * Icon Generator for ZipMerge - Run this to generate app icon
 * Instructions:
 * 1. Open this file in Xcode Playground or add to project temporarily
 * 2. Run and screenshot the preview at different sizes
 * 3. Use the screenshots for your app icon
 *
 */

import SwiftUI

struct AppIconView: View {
    let size: CGFloat = 1024 // Standard app icon size

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.2, green: 0.5, blue: 0.9),
                    Color(red: 0.1, green: 0.3, blue: 0.7)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Main icon content
            VStack(spacing: size * 0.05) {
                // Zip icon on top
                Image(systemName: "doc.zipper")
                    .font(.system(size: size * 0.25, weight: .medium))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: size * 0.02)

                // Merge arrows
                HStack(spacing: size * 0.08) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: size * 0.15, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))

                    Image(systemName: "arrow.triangle.merge")
                        .font(.system(size: size * 0.15, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.2))
                        .shadow(color: .black.opacity(0.3), radius: size * 0.01)
                }

                // Folder icon at bottom
                Image(systemName: "folder.fill")
                    .font(.system(size: size * 0.2, weight: .medium))
                    .foregroundColor(.white.opacity(0.95))
                    .shadow(color: .black.opacity(0.3), radius: size * 0.02)
            }
        }
        .frame(width: size, height: size)
        .cornerRadius(size * 0.225) // Standard iOS icon corner radius
    }
}

// Alternative simpler design
struct AppIconViewSimple: View {
    let size: CGFloat = 1024

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: size * 0.225)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.3, green: 0.6, blue: 1.0),
                        Color(red: 0.2, green: 0.4, blue: 0.8)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                ))

            // Zipper merge symbol
            VStack(spacing: size * 0.08) {
                // Two zips merging
                HStack(spacing: size * 0.06) {
                    Image(systemName: "doc.zipper")
                        .font(.system(size: size * 0.22, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                        .rotationEffect(.degrees(-15))

                    Image(systemName: "arrow.right")
                        .font(.system(size: size * 0.15, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.9, blue: 0.3))

                    Image(systemName: "doc.zipper")
                        .font(.system(size: size * 0.22, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                        .rotationEffect(.degrees(15))
                }

                // Merge result
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: size * 0.18, weight: .bold))
                    .foregroundColor(Color(red: 0.3, green: 0.9, blue: 0.5))
                    .shadow(color: .black.opacity(0.3), radius: size * 0.02)
            }
        }
        .frame(width: size, height: size)
    }
}

// Preview for both designs
struct IconPreview: View {
    var body: some View {
        VStack(spacing: 40) {
            Text("Design 1: Zip to Folder Flow")
                .font(.title)
            AppIconView()
                .frame(width: 512, height: 512)

            Text("Design 2: Zip Merge Simple")
                .font(.title)
            AppIconViewSimple()
                .frame(width: 512, height: 512)
        }
        .padding(50)
        .background(Color(white: 0.9))
    }
}

#Preview {
    IconPreview()
}
