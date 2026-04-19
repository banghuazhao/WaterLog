//
// Created by Banghua Zhao on 19/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct AddDrinkTypeSheet: View {
  @Environment(\.dismiss) private var dismiss
  let appModel: AppModel

  @State private var name = ""
  @State private var iconName = "drop.fill"
  @State private var tintHex = "#38BDF8"

  var body: some View {
    NavigationStack {
      Form {
        Section("Name") {
          TextField("Display name", text: $name)
        }
        DrinkIconPickerSection(iconName: $iconName)
        DrinkColorPickerSection(tintHex: $tintHex)
        DrinkStylePreviewSection(name: name, iconName: iconName, tintHex: tintHex)
      }
      .navigationTitle("New drink")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") { save() }
            .fontWeight(.semibold)
            .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
      }
    }
  }

  private func save() {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    do {
      try appModel.addDrinkType(name: trimmed, iconName: iconName, tintHex: tintHex)
      dismiss()
    } catch {}
  }
}
