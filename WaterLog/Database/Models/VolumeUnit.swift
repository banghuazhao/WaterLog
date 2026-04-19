//
// Created by Banghua Zhao on 19/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

enum VolumeUnit: String, CaseIterable, Identifiable, Sendable {
  case metric
  case imperial

  var id: String { rawValue }

  var title: String {
    switch self {
    case .metric: "Milliliters (ml)"
    case .imperial: "Fluid ounces (fl oz)"
    }
  }

  var shortLabel: String {
    switch self {
    case .metric: "ml"
    case .imperial: "fl oz"
    }
  }
}

enum WaterLogNotification {
  static let reminderCategory = "waterlog.reminder"
  static let logAction = "LOG_WATER"
}
