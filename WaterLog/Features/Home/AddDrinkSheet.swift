//
// Created by Banghua Zhao on 19/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct AddDrinkSheet: View {
  @Environment(\.dismiss) private var dismiss
  let appModel: AppModel
  let defaultDate: Date

  @State private var selectedTypeID: DrinkType.ID?
  @State private var volumeMl: Double = 250
  @State private var loggedAt: Date = .now

  private var unit: VolumeUnit { appModel.appSettings.unit }

  private var mlPresets: [Double] {
    [150, 200, 250, 330, 500, 750, 1000]
  }

  private var imperialPresetsMl: [Double] {
    [8, 12, 16, 20, 24, 32].map { VolumeFormatting.flOzToMl(Double($0)) }
  }

  /// Slider uses milliliters; labels follow Settings unit.
  private let volumeRange: ClosedRange<Double> = 25...2000
  private var sliderStep: Double {
    unit == .metric ? 5 : max(1, VolumeFormatting.mlPerFlOz / 8)
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          typeSection
          volumeSection
          timeSection
        }
        .padding()
      }
      .background(Color(.systemGroupedBackground))
      .navigationTitle("Add drink")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") { save() }
            .fontWeight(.semibold)
            .disabled(selectedTypeID == nil || volumeMl <= 0)
        }
      }
      .onAppear {
        loggedAt = defaultDate
        if selectedTypeID == nil {
          selectedTypeID = appModel.drinkTypes.first?.id
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
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                  .fill(selected ? Color.accentColor.opacity(0.15) : Color(.secondarySystemGroupedBackground))
              )
              .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                  .strokeBorder(selected ? Color.accentColor : Color.clear, lineWidth: 2)
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

      VStack(alignment: .leading, spacing: 8) {
        HStack(alignment: .firstTextBaseline) {
          Text("Amount")
            .font(.subheadline)
            .foregroundStyle(.secondary)
          Spacer()
          Text(VolumeFormatting.format(ml: volumeMl, unit: unit))
            .font(.title2.weight(.bold).monospacedDigit())
            .multilineTextAlignment(.trailing)
        }
        Slider(value: $volumeMl, in: volumeRange, step: sliderStep)
          .tint(Color.accentColor)
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
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .fill(Color(.secondarySystemGroupedBackground))
      )

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
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                  .fill(selected ? Color.accentColor : Color(.secondarySystemGroupedBackground))
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
      DatePicker("Logged at", selection: $loggedAt, displayedComponents: [.date, .hourAndMinute])
        .datePickerStyle(.compact)
        .padding()
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(.secondarySystemGroupedBackground)))
    }
  }

  private func save() {
    guard let selectedTypeID else { return }
    do {
      try appModel.addDrinkLog(drinkTypeID: selectedTypeID, volumeMl: volumeMl, loggedAt: loggedAt)
      dismiss()
    } catch {
      // Surface error in production; for now ignore
    }
  }
}
