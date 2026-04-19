//
// Created by Banghua Zhao on 19/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

enum VolumeFormatting {
  static let mlPerFlOz = 29.5735295625

  static func mlToFlOz(_ ml: Double) -> Double {
    ml / mlPerFlOz
  }

  static func flOzToMl(_ flOz: Double) -> Double {
    flOz * mlPerFlOz
  }

  static func format(ml: Double, unit: VolumeUnit) -> String {
    switch unit {
    case .metric:
      let rounded = (ml / 10).rounded() * 10
      return "\(Int(rounded)) ml"
    case .imperial:
      let oz = mlToFlOz(ml)
      return String(format: "%.1f fl oz", oz)
    }
  }

  static func formatCompact(ml: Double, unit: VolumeUnit) -> String {
    switch unit {
    case .metric:
      "\(Int(ml.rounded())) ml"
    case .imperial:
      String(format: "%.1f fl oz", mlToFlOz(ml))
    }
  }
}
