//
// Created by Banghua Zhao on 19/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import UIKit

extension Color {
  init(hex: String) {
    let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: cleaned).scanHexInt64(&int)
    let a, r, g, b: UInt64
    switch cleaned.count {
    case 3:
      (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6:
      (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8:
      (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
      (a, r, g, b) = (255, 56, 189, 248)
    }
    self.init(
      .sRGB,
      red: Double(r) / 255,
      green: Double(g) / 255,
      blue: Double(b) / 255,
      opacity: Double(a) / 255
    )
  }

  /// Encodes as `#RRGGBB` for persisted drink accents (opaque sRGB).
  func hexStringForStorage() -> String {
    let ui = UIColor(self)
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0
    if ui.getRed(&r, green: &g, blue: &b, alpha: &a) {
      return String(
        format: "#%02X%02X%02X",
        Int(round(r * 255)),
        Int(round(g * 255)),
        Int(round(b * 255))
      )
    }
    guard let comps = ui.cgColor.components, comps.count >= 3 else {
      return "#38BDF8"
    }
    return String(
      format: "#%02X%02X%02X",
      Int(round(comps[0] * 255)),
      Int(round(comps[1] * 255)),
      Int(round(comps[2] * 255))
    )
  }
}
