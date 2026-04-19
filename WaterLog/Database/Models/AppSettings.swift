//
// Created by Banghua Zhao on 19/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import SQLiteData

@Table("appSettings")
nonisolated struct AppSettings: Identifiable, Hashable, Sendable {
  /// Single configuration row.
  let id: Int
  var dailyGoalMl: Double
  var unitRaw: String
  var remindersEnabled: Bool
  var reminderIntervalMinutes: Int
  /// Minutes from midnight (0–1439), optional quiet window start.
  var quietHoursStartMinutes: Int?
  var quietHoursEndMinutes: Int?

  var unit: VolumeUnit {
    get { VolumeUnit(rawValue: unitRaw) ?? .metric }
    set { unitRaw = newValue.rawValue }
  }
}
