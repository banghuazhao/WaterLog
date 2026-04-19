//
// Created by Banghua Zhao on 19/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import Observation

@Observable @MainActor
final class HomeViewModel {
  let appModel: AppModel
  var selectedDate: Date = .now
  var isPresentingAddDrink = false
  var editingLog: DrinkLog?

  init(appModel: AppModel) {
    self.appModel = appModel
  }

  func logs(for day: Date) -> [DrinkLog] {
    appModel.logs(on: day)
  }

  func totalMl(for day: Date) -> Double {
    appModel.totalVolumeMl(on: day)
  }

  func progress(for day: Date) -> Double {
    let goal = appModel.appSettings.dailyGoalMl
    guard goal > 0 else { return 0 }
    return min(1, appModel.totalVolumeMl(on: day) / goal)
  }

  func shiftDay(_ delta: Int) {
    if let d = Calendar.current.date(byAdding: .day, value: delta, to: selectedDate) {
      selectedDate = d
    }
  }
}
