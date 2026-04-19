//
// Created by Banghua Zhao on 19/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct DrinkDetailView: View {
    @Bindable var appModel: AppModel
    let drinkType: DrinkType
    @State private var monthAnchor: Date = .now
    @State private var isEditing = false
    @State private var editName: String = ""
    @State private var editIcon: String = ""
    @State private var editTint: String = ""
    @Environment(\.dismiss) private var dismiss

    private var currentType: DrinkType {
        appModel.drinkTypes.first { $0.id == drinkType.id } ?? drinkType
    }

    private var unit: VolumeUnit { appModel.appSettings.unit }

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    Image(systemName: currentType.iconName)
                        .font(.largeTitle)
                        .foregroundStyle(Color(hex: currentType.tintHex))
                        .frame(width: 64, height: 64)
                        .background(
                            Circle()
                                .fill(Color(.secondarySystemGroupedBackground))
                                .overlay {
                                    Circle()
                                        .strokeBorder(WaterLogTheme.accent.opacity(0.22), lineWidth: 2)
                                }
                        )
                    VStack(alignment: .leading, spacing: 6) {
                        Text(currentType.name)
                            .font(.title2.weight(.bold))
                        Text("Created \(currentType.createdAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("This month") {
                DrinkHeatmapCalendar(
                    month: monthAnchor,
                    counts: appModel.dayCounts(for: currentType.id, inMonthOf: monthAnchor)
                )
                HStack(spacing: 12) {
                    Button {
                        shiftMonth(-1)
                    } label: {
                        Label("Previous month", systemImage: "chevron.left.circle.fill")
                            .labelStyle(.iconOnly)
                            .font(.title2)
                            .foregroundStyle(WaterLogTheme.accentMuted)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Previous month")

                    Spacer(minLength: 8)

                    Text(monthAnchor.formatted(.dateTime.month(.wide).year()))
                        .font(.subheadline.weight(.semibold))
                        .multilineTextAlignment(.center)

                    Spacer(minLength: 8)

                    Button {
                        shiftMonth(1)
                    } label: {
                        Label("Next month", systemImage: "chevron.right.circle.fill")
                            .labelStyle(.iconOnly)
                            .font(.title2)
                            .foregroundStyle(WaterLogTheme.accentMuted)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Next month")
                }
                .padding(.vertical, 6)
                .listRowSeparator(.hidden, edges: .bottom)
            }

            Section("Totals (last 30 days)") {
                let total = recentVolumeMl(days: 30)
                LabeledContent("Volume", value: VolumeFormatting.format(ml: total, unit: unit))
                LabeledContent("Servings", value: "\(recentLogs(days: 30).count)")
            }

            Section {
                Button("Edit drink") {
                    editName = currentType.name
                    editIcon = currentType.iconName
                    editTint = currentType.tintHex
                    isEditing = true
                }
                Button(role: .destructive) {
                    try? appModel.deleteDrinkType(currentType)
                    dismiss()
                } label: {
                    Text("Delete drink type")
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background {
            WaterLogTheme.secondaryScreenBackground.ignoresSafeArea()
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isEditing) {
            NavigationStack {
                Form {
                    Section("Name") {
                        TextField("Display name", text: $editName)
                    }
                    DrinkIconPickerSection(iconName: $editIcon)
                    DrinkColorPickerSection(tintHex: $editTint)
                    DrinkStylePreviewSection(name: editName, iconName: editIcon, tintHex: editTint)
                }
                .navigationTitle("Edit drink")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { isEditing = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            var next = currentType
                            next.name = editName.trimmingCharacters(in: .whitespacesAndNewlines)
                            next.iconName = editIcon
                            next.tintHex = editTint
                            try? appModel.updateDrinkType(next)
                            isEditing = false
                        }
                        .disabled(editName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
    }

    private func shiftMonth(_ delta: Int) {
        if let d = Calendar.current.date(byAdding: .month, value: delta, to: monthAnchor) {
            monthAnchor = d
        }
    }

    private func recentLogs(days: Int) -> [DrinkLog] {
        let start = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return appModel.logs(for: currentType.id).filter { $0.loggedAt >= start }
    }

    private func recentVolumeMl(days: Int) -> Double {
        recentLogs(days: days).reduce(0) { $0 + $1.volumeMl }
    }
}

private struct DrinkHeatmapCalendar: View {
    let month: Date
    let counts: [Date: Int]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        let cal = Calendar.current
        let weekdayLetters: [String] = (0 ..< 7).map { col in
            let idx = (col + cal.firstWeekday - 1) % 7
            return String(cal.shortWeekdaySymbols[idx].prefix(1))
        }
        VStack(alignment: .leading, spacing: 10) {
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(0 ..< 7, id: \.self) { col in
                    Text(weekdayLetters[col].uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
                ForEach(Array(daysInMonthGrid().enumerated()), id: \.offset) { _, slot in
                    if let day = slot {
                        let c = counts[day] ?? 0
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(intensityColor(count: c))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                Text("\(cal.component(.day, from: day))")
                                    .font(.caption2.weight(c > 0 ? .bold : .regular))
                                    .foregroundStyle(c > 0 ? Color.white : Color.secondary)
                            }
                    } else {
                        Color.clear.aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
    }

    private func intensityColor(count: Int) -> Color {
        switch count {
        case 0: return Color(.tertiarySystemFill)
        case 1: return WaterLogTheme.accent.opacity(0.38)
        case 2: return WaterLogTheme.accent.opacity(0.58)
        default: return WaterLogTheme.accent.opacity(0.88)
        }
    }

    private func daysInMonthGrid() -> [Date?] {
        let cal = Calendar.current
        guard let interval = cal.dateInterval(of: .month, for: month) else { return [] }
        let startWeekday = cal.component(.weekday, from: interval.start)
        let first = cal.firstWeekday
        let padding = (startWeekday - first + 7) % 7
        var cells: [Date?] = Array(repeating: nil, count: padding)
        var day = interval.start
        while day < interval.end {
            cells.append(day)
            day = cal.date(byAdding: .day, value: 1, to: day)!
        }
        while cells.count % 7 != 0 {
            cells.append(nil)
        }
        return cells
    }
}
