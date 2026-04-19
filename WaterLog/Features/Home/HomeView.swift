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
                if appModel.drinkTypes.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "Create a drink first",
                            systemImage: "cup.and.saucer",
                            description: Text("Add a drink type (for example water or tea), then you can log servings here.")
                        )
                        .frame(minHeight: 120)
                        .listRowBackground(Color.clear)
                        Button {
                            homeViewModel.isPresentingAddDrinkType = true
                        } label: {
                            Text("Create drink type")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(WaterLogTheme.accent)
                        .listRowBackground(Color.clear)
                    }
                }

                Section {
                    progressCard
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                if logs.isEmpty, !appModel.drinkTypes.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "No drinks yet",
                            systemImage: "drop.circle",
                            description: Text("Tap + to add, or pick another day.")
                        )
                        .frame(minHeight: 160)
                        .listRowBackground(Color.clear)
                    }
                } else if !logs.isEmpty {
                    Section {
                        ForEach(logs) { log in
                            logRowLabel(log)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    homeViewModel.editingLog = log
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        do {
                                            try appModel.deleteDrinkLog(log)
                                        } catch {
                                            appModel.presentError(error)
                                        }
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
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .textCase(nil)
                            Spacer()
                            Text("\(logs.count)")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(WaterLogTheme.contentStackSpacing)
            .scrollContentBackground(.hidden)
            .background {
                WaterLogTheme.homeBackground.ignoresSafeArea()
            }
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
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(WaterLogTheme.accentMuted)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Previous day")
                        DatePicker(
                            "",
                            selection: $homeViewModel.selectedDate,
                            displayedComponents: [.date]
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .accessibilityLabel("Selected day")
                        Button {
                            homeViewModel.shiftDay(1)
                        } label: {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.body)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(WaterLogTheme.accentMuted)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Next day")
                    }
                    .frame(maxWidth: .infinity)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if appModel.drinkTypes.isEmpty {
                            homeViewModel.isPresentingAddDrinkType = true
                        } else {
                            homeViewModel.isPresentingAddDrink = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.title3)
                            .foregroundStyle(WaterLogTheme.accent)
                    }
                    .accessibilityLabel(appModel.drinkTypes.isEmpty ? "Add drink type" : "Add drink")
                }
            }
            .sheet(isPresented: $homeViewModel.isPresentingAddDrink) {
                AddDrinkSheet(appModel: appModel, defaultDate: homeViewModel.selectedDate)
            }
            .sheet(isPresented: $homeViewModel.isPresentingAddDrinkType) {
                AddDrinkTypeSheet(appModel: appModel)
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
        let goalLabel = goal > 0
            ? "of \(VolumeFormatting.format(ml: goal, unit: unit))"
            : "Set a daily goal in Settings"

        return VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 14)
                if goal > 0 {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            WaterLogTheme.progressRingGradient,
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(duration: 0.55), value: progress)
                }
                VStack(spacing: 4) {
                    Text(VolumeFormatting.format(ml: total, unit: unit))
                        .font(.title2.weight(.bold))
                        .monospacedDigit()
                    Text(goalLabel)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(width: 160, height: 160)
            .padding(.top, 4)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Daily hydration")
            .accessibilityValue(
                goal > 0
                    ? "\(VolumeFormatting.format(ml: total, unit: unit)) of \(VolumeFormatting.format(ml: goal, unit: unit)) goal"
                    : "\(VolumeFormatting.format(ml: total, unit: unit)) logged, no goal set"
            )

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
        .background {
            RoundedRectangle(cornerRadius: WaterLogTheme.cornerRadiusCard, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: WaterLogTheme.cornerRadiusCard, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                }
        }
        .shadow(color: .black.opacity(0.06), radius: 14, x: 0, y: 6)
        .padding(.horizontal, 4)
    }

    private func logRowLabel(_ log: DrinkLog) -> some View {
        let type = appModel.drinkType(id: log.drinkTypeID)
        let unit = appModel.appSettings.unit
        return HStack(spacing: 14) {
            Image(systemName: type?.iconName ?? "questionmark.circle")
                .font(.title3)
                .foregroundStyle(Color(hex: type?.tintHex ?? "#888888"))
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color(.secondarySystemGroupedBackground))
                        .overlay {
                            Circle().strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                        }
                )
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(type?.name ?? "Drink"), \(VolumeFormatting.format(ml: log.volumeMl, unit: unit)), \(log.loggedAt.formatted(date: .omitted, time: .shortened))"
        )
    }
}
