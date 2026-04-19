//
// Created by Banghua Zhao on 19/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import SQLiteData

@Table("drinkTypes")
nonisolated struct DrinkType: Identifiable, Hashable, Sendable {
  let id: Int
  var name: String
  var iconName: String
  var tintHex: String
  var sortOrder: Int
  var createdAt: Date
}
