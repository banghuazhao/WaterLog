//
// Created by Banghua Zhao on 19/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct HomeView: View {
  @Bindable var homeViewModel: HomeViewModel
  private var appModel: AppModel { homeViewModel.appModel }

  private var logs: [DrinkLog] {
    homeViewModel.logs(for: homeViewModel.selectedDate)
  }

  var body: some View {
    NavigationStack {
      List {
        Section {
          progressCard
            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }

        if logs.isEmpty {
          Section {
            ContentUnavailableView(
              "No drinks yet",
              systemImage: "drop.circle",
              description: Text("Tap + to add, or pick another day.")
            )
            .frame(minHeight: 160)
            .listRowBackground(Color.clear)
          }
        } else {
          Section {
            ForEach(logs) { log in
              logRowLabel(log)
                .contentShape(Rectangle())
                .onTapGesture {
                  homeViewModel.editingLog = log
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                  Button(role: .destructive) {
                    try? appModel.deleteDrinkLog(log)
                  } label: {
                    Label("Delete", systemImage: "trash")
                  }
                }
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Double tap to edit, swipe left to delete.")
            }
          } header: {
            HStack {
              Text("Drinks logged")
              Spacer()
              Text("\(logs.count)")
                .foregroundStyle(.secondary)
            }
          }
        }
      }
      .listStyle(.insetGrouped)
      .scrollContentBackground(.hidden)
      .background(
        LinearGradient(
          colors: [
            Color(red: 0.06, green: 0.45, blue: 0.62).opacity(0.12),
            Color(.systemGroupedBackground),
          ],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
      .navigationTitle("Home")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .principal) {
          HStack(spacing: 4) {
            Button {
              homeViewModel.shiftDay(-1)
            } label: {
              Image(systemName: "chevron.left.circle.fill")
                .font(.body)
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            DatePicker(
              "",
              selection: $homeViewModel.selectedDate,
              displayedComponents: [.date]
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            Button {
              homeViewModel.shiftDay(1)
            } label: {
              Image(systemName: "chevron.right.circle.fill")
                .font(.body)
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
          }
          .frame(maxWidth: .infinity)
        }
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            homeViewModel.isPresentingAddDrink = true
          } label: {
            Image(systemName: "plus.circle.fill")
              .symbolRenderingMode(.hierarchical)
              .font(.title3)
          }
          .accessibilityLabel("Add drink")
        }
      }
      .sheet(isPresented: $homeViewModel.isPresentingAddDrink) {
        AddDrinkSheet(appModel: appModel, defaultDate: homeViewModel.selectedDate)
      }
      .sheet(item: $homeViewModel.editingLog) { log in
        EditDrinkLogSheet(log: log, appModel: appModel)
      }
    }
  }

  private var progressCard: some View {
    let day = homeViewModel.selectedDate
    let total = homeViewModel.totalMl(for: day)
    let goal = appModel.appSettings.dailyGoalMl
    let progress = homeViewModel.progress(for: day)
    let unit = appModel.appSettings.unit

    return VStack(spacing: 16) {
      ZStack {
        Circle()
          .stroke(Color(.systemGray5), lineWidth: 14)
        Circle()
          .trim(from: 0, to: progress)
          .stroke(
            AngularGradient(
              colors: [.cyan, .blue, .mint],
              center: .center
            ),
            style: StrokeStyle(lineWidth: 14, lineCap: .round)
          )
          .rotationEffect(.degrees(-90))
          .animation(.spring(duration: 0.55), value: progress)
        VStack(spacing: 4) {
          Text(VolumeFormatting.format(ml: total, unit: unit))
            .font(.title2.weight(.bold))
            .monospacedDigit()
          Text("of \(VolumeFormatting.format(ml: goal, unit: unit))")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      }
      .frame(width: 160, height: 160)
      .padding(.top, 4)

      if Calendar.current.isDateInToday(day) {
        Label("Stay topped up—small sips add up fast.", systemImage: "drop.fill")
          .font(.footnote)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal)
      } else {
        Label("Viewing history for this day.", systemImage: "calendar")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 20)
    .background(
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .fill(.ultraThinMaterial)
    )
    .padding(.horizontal, 4)
  }

  private func logRowLabel(_ log: DrinkLog) -> some View {
    let type = appModel.drinkType(id: log.drinkTypeID)
    let unit = appModel.appSettings.unit
    return HStack(spacing: 14) {
      Image(systemName: type?.iconName ?? "questionmark.circle")
        .font(.title3)
        .foregroundStyle(Color(hex: type?.tintHex ?? "#888888"))
        .frame(width: 40, height: 40)
        .background(Circle().fill(Color(.secondarySystemGroupedBackground)))
      VStack(alignment: .leading, spacing: 4) {
        Text(type?.name ?? "Drink")
          .font(.body.weight(.semibold))
        Text(log.loggedAt.formatted(date: .omitted, time: .shortened))
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer()
      Text(VolumeFormatting.format(ml: log.volumeMl, unit: unit))
        .font(.subheadline.monospacedDigit().weight(.semibold))
      Image(systemName: "chevron.right")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.tertiary)
    }
    .padding(.vertical, 6)
  }
}
