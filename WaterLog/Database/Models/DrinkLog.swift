//
// Created by Banghua Zhao on 19/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import SQLiteData

@Table("drinkLogs")
nonisolated struct DrinkLog: Identifiable, Hashable, Sendable {
  let id: Int
  var drinkTypeID: DrinkType.ID
  /// Stored in milliliters for consistent goals and reporting.
  var volumeMl: Double
  var loggedAt: Date
}
