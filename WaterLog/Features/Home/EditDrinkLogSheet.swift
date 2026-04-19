//
// Created by Banghua Zhao on 19/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct EditDrinkLogSheet: View {
    @Environment(\.dismiss) private var dismiss
    let log: DrinkLog
    let appModel: AppModel

    @State private var selectedTypeID: DrinkType.ID
    @State private var volumeMl: Double
    @State private var loggedAt: Date

    private var unit: VolumeUnit { appModel.appSettings.unit }

    private var mlPresets: [Double] {
        [150, 200, 250, 330, 500, 750, 1000]
    }

    private var imperialPresetsMl: [Double] {
        [8, 12, 16, 20, 24, 32].map { VolumeFormatting.flOzToMl(Double($0)) }
    }

    private let volumeRange: ClosedRange<Double> = 25 ... 2000
    private var sliderStep: Double {
        unit == .metric ? 5 : max(1, VolumeFormatting.mlPerFlOz / 8)
    }

    init(log: DrinkLog, appModel: AppModel) {
        self.log = log
        self.appModel = appModel
        _selectedTypeID = State(initialValue: log.drinkTypeID)
        _volumeMl = State(initialValue: log.volumeMl)
        _loggedAt = State(initialValue: log.loggedAt)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: WaterLogTheme.contentStackSpacing) {
                    typeSection
                    volumeSection
                    timeSection
                    deleteSection
                }
                .padding()
            }
            .scrollContentBackground(.hidden)
            .background {
                WaterLogTheme.secondaryScreenBackground.ignoresSafeArea()
            }
            .navigationTitle("Edit drink")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(volumeMl <= 0)
                }
            }
        }
    }

    private var typeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Drink type")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(appModel.drinkTypes) { type in
                        let selected = selectedTypeID == type.id
                        Button {
                            selectedTypeID = type.id
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: type.iconName)
                                    .font(.title2)
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(Color(hex: type.tintHex))
                                Text(type.name)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 14)
                            .frame(minWidth: 88)
                            .background(
                                RoundedRectangle(cornerRadius: WaterLogTheme.cornerRadiusMedium, style: .continuous)
                                    .fill(selected ? WaterLogTheme.accent.opacity(0.15) : Color(.secondarySystemGroupedBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: WaterLogTheme.cornerRadiusMedium, style: .continuous)
                                    .strokeBorder(selected ? WaterLogTheme.accent : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var volumeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Volume")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            WLSheetPanel {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Amount")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(VolumeFormatting.format(ml: volumeMl, unit: unit))
                            .font(.title2.weight(.bold).monospacedDigit())
                    }
                    Slider(value: $volumeMl, in: volumeRange, step: sliderStep)
                        .tint(WaterLogTheme.accent)
                    HStack {
                        Text(VolumeFormatting.formatCompact(ml: volumeRange.lowerBound, unit: unit))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Spacer()
                        Text(VolumeFormatting.formatCompact(ml: volumeRange.upperBound, unit: unit))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Text("Quick picks")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 10)], spacing: 10) {
                ForEach(presets, id: \.self) { ml in
                    let selected = abs(volumeMl - ml) < 0.5
                    Button {
                        volumeMl = ml
                    } label: {
                        Text(VolumeFormatting.formatCompact(ml: ml, unit: unit))
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: WaterLogTheme.cornerRadiusSmall, style: .continuous)
                                    .fill(selected ? WaterLogTheme.accent : Color(.secondarySystemGroupedBackground))
                            )
                            .foregroundStyle(selected ? Color.white : Color.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var presets: [Double] {
        unit == .metric ? mlPresets : imperialPresetsMl
    }

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Time")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            WLSheetPanel {
                DatePicker("Logged at", selection: $loggedAt, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    .tint(WaterLogTheme.accent)
            }
        }
    }

    private var deleteSection: some View {
        Button(role: .destructive) {
            deleteLog()
        } label: {
            Label("Delete this log", systemImage: "trash")
                .frame(maxWidth: .infinity)
        }
        .foregroundStyle(.red)
        .buttonStyle(.bordered)
    }

    private func save() {
        var next = log
        next.drinkTypeID = selectedTypeID
        next.volumeMl = volumeMl
        next.loggedAt = loggedAt
        do {
            try appModel.updateDrinkLog(next)
            dismiss()
        } catch {}
    }

    private func deleteLog() {
        do {
            try appModel.deleteDrinkLog(log)
            dismiss()
        } catch {}
    }
}
