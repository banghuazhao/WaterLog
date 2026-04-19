//
// Created by Banghua Zhao on 19/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct OnboardingView: View {
  @Bindable var appModel: AppModel
  var onFinished: () -> Void

  @State private var page = 0
  @State private var goalMl: Double = 2000
  @State private var unit: VolumeUnit = .metric
  @State private var remindersOn = false

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        TabView(selection: $page) {
          welcomePage.tag(0)
          goalUnitPage.tag(1)
          remindersPage.tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))

        VStack(spacing: 12) {
          if page < 2 {
            Button {
              withAnimation { page += 1 }
            } label: {
              Text("Continue")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(WaterLogTheme.accent)
          } else {
            Button {
              applyAndFinish()
            } label: {
              Text("Get started")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(WaterLogTheme.accent)
          }
        }
        .padding()
        .background(.ultraThinMaterial)
      }
      .background {
        WaterLogTheme.secondaryScreenBackground
          .ignoresSafeArea()
      }
      .navigationTitle("WaterLog")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Skip") {
            onFinished()
          }
          .foregroundStyle(.secondary)
        }
      }
    }
    .onAppear {
      let s = appModel.appSettings
      goalMl = s.dailyGoalMl
      unit = s.unit
      remindersOn = s.remindersEnabled
    }
  }

  private var welcomePage: some View {
    VStack(spacing: 20) {
      Image(systemName: "drop.fill")
        .font(.system(size: 56))
        .foregroundStyle(WaterLogTheme.accent)
        .accessibilityHidden(true)
      Text("Track hydration your way")
        .font(.title2.weight(.bold))
        .multilineTextAlignment(.center)
      Text(
        "Log drinks by type and volume, see trends in reports, and keep goals on your device—no account required."
      )
      .font(.body)
      .foregroundStyle(.secondary)
      .multilineTextAlignment(.center)
      .padding(.horizontal)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
  }

  private var goalUnitPage: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Text("Daily goal & units")
          .font(.title3.weight(.semibold))
        Text("You can change these anytime in Settings.")
          .font(.subheadline)
          .foregroundStyle(.secondary)

        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text("Goal")
            Spacer()
            Text(VolumeFormatting.format(ml: goalMl, unit: unit))
              .font(.body.monospacedDigit().weight(.semibold))
          }
          Slider(value: $goalMl, in: 500 ... 5000, step: unit == .metric ? 50 : VolumeFormatting.mlPerFlOz)
            .tint(WaterLogTheme.accent)
        }
        .padding()
        .background {
          RoundedRectangle(cornerRadius: WaterLogTheme.cornerRadiusMedium, style: .continuous)
            .fill(Color(.secondarySystemGroupedBackground))
        }

        Picker("Units", selection: $unit) {
          ForEach(VolumeUnit.allCases) { u in
            Text(u.title).tag(u)
          }
        }
        .pickerStyle(.segmented)
      }
      .padding()
    }
  }

  private var remindersPage: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        Text("Reminders")
          .font(.title3.weight(.semibold))
        Text(
          "Optional local notifications nudge you toward your goal. You can turn them off in Settings."
        )
        .font(.subheadline)
        .foregroundStyle(.secondary)

        Toggle("Hydration reminders", isOn: $remindersOn)
          .tint(WaterLogTheme.accent)

        Text("Your data stays on this iPhone. WaterLog does not send your logs to our servers.")
          .font(.caption)
          .foregroundStyle(.secondary)
          .padding(.top, 8)
      }
      .padding()
    }
  }

  private func applyAndFinish() {
    var next = appModel.appSettings
    next.dailyGoalMl = goalMl
    next.unitRaw = unit.rawValue
    next.remindersEnabled = remindersOn
    do {
      try appModel.updateSettings(next)
      if remindersOn {
        Task {
          _ = await ReminderScheduler.requestAuthorizationIfNeeded()
        }
      }
      onFinished()
    } catch {
      appModel.presentError(error)
    }
  }
}
