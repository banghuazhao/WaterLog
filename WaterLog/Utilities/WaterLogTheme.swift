//
// Created by Banghua Zhao on 19/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

/// Shared visual language for WaterLog (spacing, radii, brand tint, backgrounds).
enum WaterLogTheme {
  static let accent = Color(red: 0.10, green: 0.52, blue: 0.82)
  static let accentMuted = Color(red: 0.10, green: 0.52, blue: 0.82).opacity(0.85)

  static let cornerRadiusCard: CGFloat = 20
  static let cornerRadiusMedium: CGFloat = 16
  static let cornerRadiusSmall: CGFloat = 12
  static let cardPadding: CGFloat = 16
  static let cardHeaderSpacing: CGFloat = 14
  static let contentStackSpacing: CGFloat = 20

  static var homeBackground: some View {
    LinearGradient(
      colors: [
        accent.opacity(0.14),
        Color(.systemGroupedBackground),
        Color(.systemGroupedBackground).opacity(0.98),
      ],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  static var secondaryScreenBackground: some View {
    LinearGradient(
      colors: [
        accent.opacity(0.06),
        Color(.systemGroupedBackground),
      ],
      startPoint: .top,
      endPoint: .bottom
    )
  }

  static var progressRingGradient: AngularGradient {
    AngularGradient(
      colors: [
        Color(red: 0.2, green: 0.75, blue: 0.85),
        accent,
        Color(red: 0.35, green: 0.65, blue: 0.95),
        Color(red: 0.45, green: 0.85, blue: 0.75),
        Color(red: 0.2, green: 0.75, blue: 0.85),
      ],
      center: .center
    )
  }

}

// MARK: - Reusable report / dashboard card

struct WLReportCard<Content: View>: View {
  let title: String
  var subtitle: String?
  @ViewBuilder var content: () -> Content

  var body: some View {
    VStack(alignment: .leading, spacing: WaterLogTheme.cardHeaderSpacing) {
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.headline)
          .foregroundStyle(.primary)
        if let subtitle, !subtitle.isEmpty {
          Text(subtitle)
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
      content()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(WaterLogTheme.cardPadding)
    .background {
      RoundedRectangle(cornerRadius: WaterLogTheme.cornerRadiusCard, style: .continuous)
        .fill(Color(.secondarySystemGroupedBackground))
        .overlay {
          RoundedRectangle(cornerRadius: WaterLogTheme.cornerRadiusCard, style: .continuous)
            .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }
    .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
  }
}

// MARK: - Sheet section container (add / edit drink)

struct WLSheetPanel<Content: View>: View {
  @ViewBuilder var content: () -> Content

  var body: some View {
    content()
      .padding(WaterLogTheme.cardPadding)
      .background {
        RoundedRectangle(cornerRadius: WaterLogTheme.cornerRadiusMedium, style: .continuous)
          .fill(Color(.secondarySystemGroupedBackground))
          .overlay {
            RoundedRectangle(cornerRadius: WaterLogTheme.cornerRadiusMedium, style: .continuous)
              .strokeBorder(Color.primary.opacity(0.05), lineWidth: 1)
          }
      }
  }
}
