//
// Created by Banghua Zhao on 19/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

/// Curated SF Symbols and accent colors for drink types (visible in light and dark UI).
enum DrinkStyleOptions {
  static let sfSymbolNames: [String] = [
    "drop.fill",
    "drop.circle.fill",
    "cup.and.saucer.fill",
    "mug.fill",
    "takeoutbag.and.cup.and.straw.fill",
    "wineglass.fill",
    "bubbles.and.sparkles.fill",
    "leaf.fill",
    "sparkles",
    "flame.fill",
    "carrot.fill",
    "fish.fill",
    "fork.knife",
    "bolt.fill",
    "heart.fill",
    "moon.fill",
    "sun.max.fill",
    "snowflake",
    "cloud.fill",
    "hurricane",
    "star.fill",
    "birthday.cake.fill",
    "popcorn.fill",
  ]

  /// Avoid very light hex values so icons stay visible on grouped backgrounds.
  static let accentHexPalette: [String] = [
    "#38BDF8", "#0EA5E9", "#0369A1",
    "#22C55E", "#16A34A", "#15803D",
    "#F97316", "#EA580C", "#C2410C",
    "#A855F7", "#9333EA", "#7C3AED",
    "#EC4899", "#DB2777", "#BE185D",
    "#EAB308", "#CA8A04",
    "#64748B", "#475569",
    "#94A3B8",
    "#7C9CBF",
    "#D97757",
    "#14B8A6", "#0D9488",
  ]

  static func iconsIncludingCurrent(_ current: String) -> [String] {
    var list = sfSymbolNames
    if !list.contains(current) {
      list.insert(current, at: 0)
    }
    return list
  }

  static func hexesIncludingCurrent(_ current: String) -> [String] {
    let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
    let withHash = trimmed.hasPrefix("#") ? trimmed : "#\(trimmed)"
    var list = accentHexPalette
    let hasMatch = list.contains { $0.caseInsensitiveCompare(withHash) == .orderedSame }
    if !hasMatch, !withHash.dropFirst().isEmpty {
      list.insert(withHash, at: 0)
    }
    return list
  }
}

struct DrinkIconPickerSection: View {
  @Binding var iconName: String
  var columns: [GridItem] = [GridItem(.adaptive(minimum: 48), spacing: 10)]

  var body: some View {
    Section {
      LazyVGrid(columns: columns, spacing: 10) {
        ForEach(DrinkStyleOptions.iconsIncludingCurrent(iconName), id: \.self) { icon in
          let selected = iconName == icon
          Button {
            iconName = icon
          } label: {
            Image(systemName: icon)
              .font(.title3)
              .frame(width: 44, height: 44)
              .background(
                Circle()
                  .fill(selected ? Color.accentColor.opacity(0.22) : Color(.secondarySystemGroupedBackground))
              )
              .overlay(
                Circle()
                  .strokeBorder(selected ? Color.accentColor : Color.clear, lineWidth: 2)
              )
          }
          .buttonStyle(.plain)
          .accessibilityLabel(icon)
        }
      }
      .padding(.vertical, 4)
    } header: {
      Text("Icon")
    }
  }
}

struct DrinkColorPickerSection: View {
  @Binding var tintHex: String
  @State private var customPickerColor = Color(red: 0.22, green: 0.74, blue: 0.97)

  var body: some View {
    Section {
      LazyVGrid(
        columns: [GridItem(.adaptive(minimum: 36), spacing: 10)],
        spacing: 10
      ) {
        ForEach(
          Array(DrinkStyleOptions.hexesIncludingCurrent(tintHex).enumerated()),
          id: \.offset
        ) { _, hex in
          let selected = tintHex.caseInsensitiveCompare(hex) == .orderedSame
          Button {
            tintHex = hex
            customPickerColor = Color(hex: hex)
          } label: {
            Circle()
              .fill(Color(hex: hex))
              .frame(width: 36, height: 36)
              .overlay {
                if selected {
                  Image(systemName: "checkmark.circle.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.35), radius: 1, y: 1)
                }
              }
              .overlay(
                Circle()
                  .strokeBorder(Color.primary.opacity(0.12), lineWidth: selected ? 0 : 0.5)
              )
          }
          .buttonStyle(.plain)
          .accessibilityLabel("Preset color")
        }
      }
      .padding(.vertical, 4)

      ColorPicker("Custom color", selection: $customPickerColor, supportsOpacity: false)
        .onChange(of: customPickerColor) { _, new in
          tintHex = new.hexStringForStorage()
        }
    } header: {
      Text("Accent color")
    } footer: {
      Text("Pick a preset or choose any color. The icon preview updates as you go.")
        .font(.caption)
    }
    .onAppear {
      customPickerColor = Color(hex: tintHex)
    }
  }
}

struct DrinkStylePreviewSection: View {
  let name: String
  let iconName: String
  let tintHex: String

  var body: some View {
    Section {
      HStack {
        Text("Preview")
          .foregroundStyle(.secondary)
        Spacer()
        Label {
          Text(name.isEmpty ? "Name" : name)
            .font(.body.weight(.semibold))
        } icon: {
          Image(systemName: iconName)
            .foregroundStyle(Color(hex: tintHex))
        }
        .labelStyle(.titleAndIcon)
      }
    }
  }
}
