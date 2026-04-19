//
// Created by Banghua Zhao on 19/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct ReportDayDetailView: View {
  let dayStart: Date
  let appModel: AppModel

  private var unit: VolumeUnit { appModel.appSettings.unit }
  private var goalMl: Double { appModel.appSettings.dailyGoalMl }

  private var logs: [DrinkLog] {
    appModel.logs(on: dayStart).sorted { $0.loggedAt > $1.loggedAt }
  }

  private var totalMl: Double {
    appModel.totalVolumeMl(on: dayStart)
  }

  var body: some View {
    NavigationStack {
      List {
        Section {
          LabeledContent("Total", value: VolumeFormatting.format(ml: totalMl, unit: unit))
          if goalMl > 0 {
            LabeledContent("Daily goal", value: VolumeFormatting.format(ml: goalMl, unit: unit))
            let met = totalMl >= goalMl
            Label(met ? "Goal reached" : "Below goal", systemImage: met ? "checkmark.circle.fill" : "circle.dashed")
              .foregroundStyle(met ? .green : .secondary)
              .font(.subheadline)
          }
        } header: {
          Text(dayStart.formatted(date: .complete, time: .omitted))
        }

        if logs.isEmpty {
          Section {
            ContentUnavailableView(
              "No drinks",
              systemImage: "drop",
              description: Text("Nothing logged on this day.")
            )
            .frame(minHeight: 120)
          }
        } else {
          Section("Entries (\(logs.count))") {
            ForEach(logs) { log in
              logRow(log)
            }
          }
        }
      }
      .navigationTitle("Day detail")
      .navigationBarTitleDisplayMode(.inline)
    }
  }

  private func logRow(_ log: DrinkLog) -> some View {
    let type = appModel.drinkType(id: log.drinkTypeID)
    return HStack {
      Image(systemName: type?.iconName ?? "drop.fill")
        .foregroundStyle(Color(hex: type?.tintHex ?? "#888"))
      VStack(alignment: .leading, spacing: 2) {
        Text(type?.name ?? "Drink")
          .font(.body.weight(.medium))
        Text(log.loggedAt.formatted(date: .omitted, time: .shortened))
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer()
      Text(VolumeFormatting.format(ml: log.volumeMl, unit: unit))
        .font(.subheadline.monospacedDigit().weight(.semibold))
    }
  }
}

struct ReportDrinkTypeDetailView: View {
  let drinkType: DrinkType
  let window: AppModel.ReportWindow
  let anchor: Date
  let appModel: AppModel

  private var unit: VolumeUnit { appModel.appSettings.unit }

  private var periodLogs: [DrinkLog] {
    appModel.logs(for: drinkType.id, in: window, anchor: anchor)
  }

  private var totalMl: Double {
    periodLogs.reduce(0) { $0 + $1.volumeMl }
  }

  var body: some View {
    NavigationStack {
      List {
        Section {
          HStack(spacing: 14) {
            Image(systemName: drinkType.iconName)
              .font(.largeTitle)
              .foregroundStyle(Color(hex: drinkType.tintHex))
            VStack(alignment: .leading, spacing: 4) {
              Text(drinkType.name)
                .font(.title2.weight(.bold))
              Text("Total in period")
                .font(.caption)
                .foregroundStyle(.secondary)
              Text(VolumeFormatting.format(ml: totalMl, unit: unit))
                .font(.title3.weight(.semibold).monospacedDigit())
            }
          }
          .padding(.vertical, 4)
        }

        Section {
          LabeledContent("Entries", value: "\(periodLogs.count)")
          LabeledContent(
            "Share of volume",
            value: sharePercentText
          )
        }

        if periodLogs.isEmpty {
          Section {
            ContentUnavailableView(
              "No entries",
              systemImage: "cup.and.saucer",
              description: Text("This drink was not logged in this period.")
            )
            .frame(minHeight: 120)
          }
        } else {
          Section("Log history") {
            ForEach(periodLogs.sorted { $0.loggedAt > $1.loggedAt }) { log in
              HStack {
                Text(log.loggedAt.formatted(date: .abbreviated, time: .shortened))
                  .font(.subheadline)
                Spacer()
                Text(VolumeFormatting.format(ml: log.volumeMl, unit: unit))
                  .font(.subheadline.monospacedDigit().weight(.medium))
              }
            }
          }
        }
      }
      .navigationTitle("Drink detail")
      .navigationBarTitleDisplayMode(.inline)
    }
  }

  private var sharePercentText: String {
    let windowTotal = appModel.totalVolumeMl(in: window, anchor: anchor)
    guard windowTotal > 0 else { return "—" }
    let p = totalMl / windowTotal * 100
    return String(format: "%.0f%%", p)
  }
}
