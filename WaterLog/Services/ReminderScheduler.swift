//
// Created by Banghua Zhao on 19/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import UserNotifications

@MainActor
enum ReminderScheduler {
  private static let prefix = "com.appsbay.WaterLog.reminder."
  private static let maxScheduled = 48

  static func requestAuthorizationIfNeeded() async -> Bool {
    let center = UNUserNotificationCenter.current()
    let settings = await center.notificationSettings()
    switch settings.authorizationStatus {
    case .authorized, .provisional, .ephemeral:
      return true
    case .notDetermined:
      do {
        return try await center.requestAuthorization(options: [.alert, .sound, .badge])
      } catch {
        return false
      }
    default:
      return false
    }
  }

  static func reschedule(settings: AppSettings) async {
    let center = UNUserNotificationCenter.current()
    center.removeAllPendingNotificationRequests()
    guard settings.remindersEnabled else { return }

    let ok = await requestAuthorizationIfNeeded()
    guard ok else { return }

    let intervalMinutes = max(30, settings.reminderIntervalMinutes)
    let quietStart = settings.quietHoursStartMinutes
    let quietEnd = settings.quietHoursEndMinutes

    var dates = upcomingFireDates(
      startingFrom: Date(),
      count: maxScheduled,
      intervalMinutes: intervalMinutes,
      quietStartMinutes: quietStart,
      quietEndMinutes: quietEnd
    )

    if dates.isEmpty {
      dates = stride(from: 0, to: maxScheduled, by: 1).map {
        Date().addingTimeInterval(TimeInterval(($0 + 1) * intervalMinutes * 60))
      }
    }

    for (index, fireDate) in dates.enumerated() {
      let content = UNMutableNotificationContent()
      content.title = "Hydration check-in"
      content.body = "Take a moment to log a drink and stay on track."
      content.sound = .default
      content.categoryIdentifier = WaterLogNotification.reminderCategory
      content.userInfo = ["action": WaterLogNotification.logAction]

      let comps = Calendar.current.dateComponents(
        [.year, .month, .day, .hour, .minute, .second],
        from: fireDate
      )
      let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
      let request = UNNotificationRequest(
        identifier: "\(prefix)\(index)",
        content: content,
        trigger: trigger
      )
      try? await center.add(request)
    }
  }

  /// Generates upcoming reminder times, skipping a quiet window when both endpoints are set.
  static func upcomingFireDates(
    startingFrom start: Date,
    count: Int,
    intervalMinutes: Int,
    quietStartMinutes: Int?,
    quietEndMinutes: Int?,
    calendar: Calendar = .current
  ) -> [Date] {
    guard let startM = quietStartMinutes, let endM = quietEndMinutes, count > 0 else {
      return (0..<count).map { start.addingTimeInterval(TimeInterval(($0 + 1) * intervalMinutes * 60)) }
    }

    func isQuiet(_ date: Date) -> Bool {
      let minutes = calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
      if startM == endM { return false }
      if startM > endM {
        return minutes >= startM || minutes < endM
      }
      return minutes >= startM && minutes < endM
    }

    var results: [Date] = []
    var cursor = start
    var safety = 0
    let step = TimeInterval(intervalMinutes * 60)
    while results.count < count, safety < 10_000 {
      safety += 1
      cursor = cursor.addingTimeInterval(step)
      if isQuiet(cursor) {
        var advance = cursor
        while isQuiet(advance), safety < 10_000 {
          safety += 1
          advance = advance.addingTimeInterval(60)
        }
        cursor = advance
      }
      results.append(cursor)
    }
    return results
  }
}
