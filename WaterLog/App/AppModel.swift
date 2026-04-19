//
// Created by Banghua Zhao on 19/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import Foundation
import Observation
import SQLiteData

@Observable @MainActor
final class AppModel {
  @ObservationIgnored
  @FetchAll(DrinkType.order(by: \.sortOrder))
  var drinkTypes: [DrinkType]

  @ObservationIgnored
  @FetchAll(DrinkLog.order(by: \.loggedAt))
  var drinkLogs: [DrinkLog]

  @ObservationIgnored
  @FetchOne(AppSettings.find(1))
  private var appSettingsRow: AppSettings?

  @ObservationIgnored
  @Dependency(\.defaultDatabase) private var database

  var appSettings: AppSettings {
    appSettingsRow
      ?? AppSettings(
        id: 1,
        dailyGoalMl: 2000,
        unitRaw: VolumeUnit.metric.rawValue,
        remindersEnabled: false,
        reminderIntervalMinutes: 120,
        quietHoursStartMinutes: 22 * 60,
        quietHoursEndMinutes: 7 * 60
      )
  }

  func drinkType(id: DrinkType.ID) -> DrinkType? {
    drinkTypes.first { $0.id == id }
  }

  func logs(on day: Date, calendar: Calendar = .current) -> [DrinkLog] {
    drinkLogs.filter { calendar.isDate($0.loggedAt, inSameDayAs: day) }
      .sorted { $0.loggedAt > $1.loggedAt }
  }

  func totalVolumeMl(on day: Date, calendar: Calendar = .current) -> Double {
    logs(on: day, calendar: calendar).reduce(0) { $0 + $1.volumeMl }
  }

  func logs(for drinkTypeID: DrinkType.ID) -> [DrinkLog] {
    drinkLogs.filter { $0.drinkTypeID == drinkTypeID }.sorted { $0.loggedAt > $1.loggedAt }
  }

  func dayCounts(for drinkTypeID: DrinkType.ID, inMonthOf reference: Date) -> [Date: Int] {
    guard let interval = Calendar.current.dateInterval(of: .month, for: reference) else {
      return [:]
    }
    var map: [Date: Int] = [:]
    for log in drinkLogs where log.drinkTypeID == drinkTypeID {
      guard log.loggedAt >= interval.start, log.loggedAt < interval.end else { continue }
      let day = Calendar.current.startOfDay(for: log.loggedAt)
      map[day, default: 0] += 1
    }
    return map
  }

  func addDrinkLog(drinkTypeID: DrinkType.ID, volumeMl: Double, loggedAt: Date = .now) throws {
    try database.write { db in
      _ = try DrinkLog.insert {
        DrinkLog.Draft(
          drinkTypeID: drinkTypeID,
          volumeMl: volumeMl,
          loggedAt: loggedAt
        )
      }
      .execute(db)
    }
  }

  func deleteDrinkLog(_ log: DrinkLog) throws {
    try database.write { db in
      try DrinkLog.delete(log).execute(db)
    }
  }

  func updateDrinkLog(_ log: DrinkLog) throws {
    try database.write { db in
      try DrinkLog.update(log).execute(db)
    }
  }

  /// Inclusive start, exclusive end — matches reporting and `dailyTotals`.
  func reportInterval(
    for window: ReportWindow,
    anchor: Date,
    calendar: Calendar = .current
  ) -> DateInterval? {
    switch window {
    case .day:
      let start = calendar.startOfDay(for: anchor)
      guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return nil }
      return DateInterval(start: start, end: end)
    case .week:
      guard
        let start = calendar.date(
          from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: anchor)
        ),
        let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start)
      else { return nil }
      return DateInterval(start: start, end: end)
    case .month:
      let comps = calendar.dateComponents([.year, .month], from: anchor)
      guard let start = calendar.date(from: comps),
        let end = calendar.date(byAdding: .month, value: 1, to: start)
      else { return nil }
      return DateInterval(start: start, end: end)
    }
  }

  func logs(in window: ReportWindow, anchor: Date, calendar: Calendar = .current) -> [DrinkLog] {
    guard let interval = reportInterval(for: window, anchor: anchor, calendar: calendar) else {
      return []
    }
    return drinkLogs
      .filter { $0.loggedAt >= interval.start && $0.loggedAt < interval.end }
      .sorted { $0.loggedAt > $1.loggedAt }
  }

  func totalVolumeMl(in window: ReportWindow, anchor: Date, calendar: Calendar = .current) -> Double {
    logs(in: window, anchor: anchor, calendar: calendar).reduce(0) { $0 + $1.volumeMl }
  }

  /// Mean volume per calendar day in the window (including zero days).
  func averageVolumeMlPerDay(in window: ReportWindow, anchor: Date, calendar: Calendar = .current)
    -> Double
  {
    let days = dailyTotals(in: window, anchor: anchor, calendar: calendar)
    guard !days.isEmpty else { return 0 }
    let sum = days.reduce(0) { $0 + $1.totalMl }
    return sum / Double(days.count)
  }

  /// Days in range where total at least meets the daily goal.
  func daysMeetingGoal(
    in window: ReportWindow,
    anchor: Date,
    goalMl: Double,
    calendar: Calendar = .current
  ) -> Int {
    dailyTotals(in: window, anchor: anchor, calendar: calendar)
      .filter { $0.totalMl >= goalMl }
      .count
  }

  /// Hour-of-day totals (0–23) for logs in the window.
  func hourlyVolumeMl(in window: ReportWindow, anchor: Date, calendar: Calendar = .current) -> [
    (hour: Int, ml: Double)
  ] {
    var buckets = Array(repeating: 0.0, count: 24)
    for log in logs(in: window, anchor: anchor, calendar: calendar) {
      let h = calendar.component(.hour, from: log.loggedAt)
      buckets[h] += log.volumeMl
    }
    return (0..<24).map { (hour: $0, ml: buckets[$0]) }
  }

  func logs(for drinkTypeID: DrinkType.ID, in window: ReportWindow, anchor: Date, calendar: Calendar = .current)
    -> [DrinkLog]
  {
    logs(in: window, anchor: anchor, calendar: calendar).filter { $0.drinkTypeID == drinkTypeID }
  }

  func addDrinkType(name: String, iconName: String, tintHex: String) throws {
    let order = (drinkTypes.map(\.sortOrder).max() ?? -1) + 1
    try database.write { db in
      _ = try DrinkType.insert {
        DrinkType.Draft(
          name: name,
          iconName: iconName,
          tintHex: tintHex,
          sortOrder: order,
          createdAt: .now
        )
      }
      .execute(db)
    }
  }

  func updateDrinkType(_ type: DrinkType) throws {
    try database.write { db in
      try DrinkType.update(type).execute(db)
    }
  }

  func deleteDrinkType(_ type: DrinkType) throws {
    try database.write { db in
      try DrinkType.delete(type).execute(db)
    }
  }

  func updateSettings(_ settings: AppSettings) throws {
    try database.write { db in
      try AppSettings.update(settings).execute(db)
    }
    Task {
      await ReminderScheduler.reschedule(settings: settings)
    }
  }

  // MARK: - Reporting

  enum ReportWindow: String, CaseIterable, Identifiable, Sendable {
    case day
    case week
    case month
    var id: String { rawValue }
    var title: String {
      switch self {
      case .day: "Day"
      case .week: "Week"
      case .month: "Month"
      }
    }
  }

  struct DayTotal: Identifiable {
    var id: Date { dayStart }
    let dayStart: Date
    let totalMl: Double
  }

  func dailyTotals(in window: ReportWindow, anchor: Date = .now, calendar: Calendar = .current)
    -> [DayTotal]
  {
    let range: (Date, Date)
    switch window {
    case .day:
      let start = calendar.startOfDay(for: anchor)
      range = (start, calendar.date(byAdding: .day, value: 1, to: start)!)
    case .week:
      let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: anchor))!
      range = (start, calendar.date(byAdding: .weekOfYear, value: 1, to: start)!)
    case .month:
      let comps = calendar.dateComponents([.year, .month], from: anchor)
      let start = calendar.date(from: comps)!
      range = (start, calendar.date(byAdding: .month, value: 1, to: start)!)
    }

    var buckets: [Date: Double] = [:]
    var dayCursor = calendar.startOfDay(for: range.0)
    while dayCursor < range.1 {
      buckets[dayCursor] = 0
      guard let next = calendar.date(byAdding: .day, value: 1, to: dayCursor) else { break }
      dayCursor = next
    }

    for log in drinkLogs where log.loggedAt >= range.0 && log.loggedAt < range.1 {
      let day = calendar.startOfDay(for: log.loggedAt)
      buckets[day, default: 0] += log.volumeMl
    }

    return buckets.keys.sorted().map { DayTotal(dayStart: $0, totalMl: buckets[$0] ?? 0) }
  }

  func totalsByDrink(in window: ReportWindow, anchor: Date = .now, calendar: Calendar = .current)
    -> [(DrinkType, Double)]
  {
    let days = dailyTotals(in: window, anchor: anchor, calendar: calendar)
    let start = days.first?.dayStart ?? calendar.startOfDay(for: anchor)
    let end = (days.last?.dayStart).flatMap { calendar.date(byAdding: .day, value: 1, to: $0) }
      ?? calendar.date(byAdding: .day, value: 1, to: start)!

    var totals: [DrinkType.ID: Double] = [:]
    for log in drinkLogs where log.loggedAt >= start && log.loggedAt < end {
      totals[log.drinkTypeID, default: 0] += log.volumeMl
    }
    return drinkTypes.compactMap { type in
      guard let ml = totals[type.id], ml > 0 else { return nil }
      return (type, ml)
    }
    .sorted { $0.1 > $1.1 }
  }

  func makeCSVExport() -> String {
    var lines = ["loggedAtISO8601,drinkTypeName,volumeMl"]
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    for log in drinkLogs.sorted(by: { $0.loggedAt < $1.loggedAt }) {
      let name = drinkType(id: log.drinkTypeID)?.name ?? "Unknown"
      let date = formatter.string(from: log.loggedAt)
      lines.append("\(date),\(escapeCSV(name)),\(log.volumeMl)")
    }
    return lines.joined(separator: "\n")
  }

  private func escapeCSV(_ value: String) -> String {
    if value.contains(",") || value.contains("\"") {
      return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
    return value
  }
}
