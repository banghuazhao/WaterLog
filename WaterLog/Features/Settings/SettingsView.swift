//
// Created by Banghua Zhao on 19/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
  @Bindable var settingsViewModel: SettingsViewModel
  private var appModel: AppModel { settingsViewModel.appModel }

  @State private var goalMl: Double = 2000
  @State private var unit: VolumeUnit = .metric
  @State private var remindersOn = false
  @State private var intervalMinutes = 120
  @State private var quietStartHour = 22
  @State private var quietEndHour = 7

  var body: some View {
    NavigationStack {
      Form {
        Section {
          VStack(alignment: .leading, spacing: 8) {
            Text("Daily goal")
              .font(.subheadline.weight(.semibold))
            Text("A steady target makes reminders and progress easier to read.")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .padding(.vertical, 4)

          HStack {
            Text("Goal")
            Spacer()
            Text(VolumeFormatting.format(ml: goalMl, unit: unit))
              .font(.body.monospacedDigit().weight(.semibold))
          }
          Slider(value: $goalMl, in: 500...5000, step: unit == .metric ? 50 : VolumeFormatting.mlPerFlOz)
            .onChange(of: unit) { _, newUnit in
              if newUnit == .imperial {
                goalMl = (goalMl / VolumeFormatting.mlPerFlOz).rounded() * VolumeFormatting.mlPerFlOz
              }
            }
        }

        Section("Units") {
          Picker("Measurement", selection: $unit) {
            ForEach(VolumeUnit.allCases) { u in
              Text(u.title).tag(u)
            }
          }
          .pickerStyle(.inline)
        }

        Section {
          Toggle(
            "Hydration reminders",
            isOn: Binding(
              get: { remindersOn },
              set: { new in
                remindersOn = new
                Task {
                  if new {
                    let ok = await ReminderScheduler.requestAuthorizationIfNeeded()
                    if !ok { await MainActor.run { remindersOn = false } }
                  }
                  await MainActor.run { persist() }
                }
              }
            )
          )
          Stepper(value: $intervalMinutes, in: 30...360, step: 30) {
            HStack {
              Text("Every")
              Spacer()
              Text("\(intervalMinutes) min")
                .foregroundStyle(.secondary)
            }
          }
          .disabled(!remindersOn)

          Stepper(value: $quietStartHour, in: 0...23, step: 1) {
            LabeledContent("Quiet hours start", value: hourLabel(quietStartHour))
          }
          .disabled(!remindersOn)
          Stepper(value: $quietEndHour, in: 0...23, step: 1) {
            LabeledContent("Quiet hours end", value: hourLabel(quietEndHour))
          }
          .disabled(!remindersOn)

          Text("During quiet hours we schedule reminders for your next active window.")
            .font(.caption)
            .foregroundStyle(.secondary)
        } header: {
          Text("Reminders")
        }

        Section("About") {
          LabeledContent("Version", value: "1.0")
          Text("WaterLog stores everything locally")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .navigationTitle("Settings")
      .onAppear { syncFromApp() }
      .onChange(of: goalMl) { _, _ in persist() }
      .onChange(of: unit) { _, _ in persist() }
      .onChange(of: intervalMinutes) { _, _ in persist() }
      .onChange(of: quietStartHour) { _, _ in persist() }
      .onChange(of: quietEndHour) { _, _ in persist() }
    }
  }

  private func hourLabel(_ hour: Int) -> String {
    var cal = Calendar.current
    cal.timeZone = .current
    var comps = DateComponents()
    comps.hour = hour
    comps.minute = 0
    let date = cal.date(from: comps) ?? Date()
    return date.formatted(date: .omitted, time: .shortened)
  }

  private func syncFromApp() {
    let s = appModel.appSettings
    goalMl = s.dailyGoalMl
    unit = s.unit
    remindersOn = s.remindersEnabled
    intervalMinutes = s.reminderIntervalMinutes
    quietStartHour = (s.quietHoursStartMinutes ?? 22 * 60) / 60
    quietEndHour = (s.quietHoursEndMinutes ?? 7 * 60) / 60
  }

  private func persist() {
    var next = appModel.appSettings
    next.dailyGoalMl = goalMl
    next.unitRaw = unit.rawValue
    next.remindersEnabled = remindersOn
    next.reminderIntervalMinutes = intervalMinutes
    next.quietHoursStartMinutes = quietStartHour * 60
    next.quietHoursEndMinutes = quietEndHour * 60
    do {
      try appModel.updateSettings(next)
    } catch {}
  }
}
