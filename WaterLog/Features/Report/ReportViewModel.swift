//
// Created by Banghua Zhao on 19/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import Observation

@Observable @MainActor
final class ReportViewModel {
  let appModel: AppModel
  var window: AppModel.ReportWindow = .week
  var anchorDate: Date = .now
  var exportDocument: ExportDocument?
  var activeDetail: ReportDetailRoute?

  struct ExportDocument: Identifiable {
    let id = UUID()
    let url: URL
  }

  enum ReportDetailRoute: Identifiable {
    case calendarDay(Date)
    case drinkType(DrinkType)

    var id: String {
      switch self {
      case .calendarDay(let d):
        "day-\(d.timeIntervalSince1970)"
      case .drinkType(let t):
        "drink-\(t.id)"
      }
    }
  }

  init(appModel: AppModel) {
    self.appModel = appModel
  }

  func prepareExport() throws {
    let csv = appModel.makeCSVExport()
    let url = FileManager.default.temporaryDirectory.appending(path: "WaterLog-export.csv")
    try csv.write(to: url, atomically: true, encoding: .utf8)
    exportDocument = ExportDocument(url: url)
  }

  var dayTotals: [AppModel.DayTotal] {
    appModel.dailyTotals(in: window, anchor: anchorDate)
  }

  var drinkBreakdown: [(DrinkType, Double)] {
    appModel.totalsByDrink(in: window, anchor: anchorDate)
  }

  var hourlyBuckets: [(hour: Int, ml: Double)] {
    appModel.hourlyVolumeMl(in: window, anchor: anchorDate)
  }

  var totalVolumeMl: Double {
    appModel.totalVolumeMl(in: window, anchor: anchorDate)
  }

  var averagePerDayMl: Double {
    appModel.averageVolumeMlPerDay(in: window, anchor: anchorDate)
  }

  var daysMeetingGoal: Int {
    appModel.daysMeetingGoal(
      in: window,
      anchor: anchorDate,
      goalMl: appModel.appSettings.dailyGoalMl
    )
  }
}
