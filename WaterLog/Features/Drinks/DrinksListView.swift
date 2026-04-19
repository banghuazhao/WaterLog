//
// Created by Banghua Zhao on 19/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct DrinksListView: View {
    @Bindable var appModel: AppModel
    @State private var isPresentingNewType = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(appModel.drinkTypes) { type in
                        NavigationLink(value: type) {
                            HStack(spacing: 14) {
                                Image(systemName: type.iconName)
                                    .font(.title3)
                                    .foregroundStyle(Color(hex: type.tintHex))
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(Color(.secondarySystemGroupedBackground))
                                            .overlay {
                                                Circle().strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                                            }
                                    )
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(type.name)
                                        .font(.body.weight(.semibold))
                                    Text("\(appModel.logs(for: type.id).count) logs total")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Text("Your drinks")
                } footer: {
                    Text("Customize icons and colors. Deleting a drink removes its history.")
                }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(WaterLogTheme.contentStackSpacing)
            .scrollContentBackground(.hidden)
            .background {
                WaterLogTheme.secondaryScreenBackground.ignoresSafeArea()
            }
            .navigationTitle("Drinks")
            .navigationDestination(for: DrinkType.self) { type in
                DrinkDetailView(appModel: appModel, drinkType: type)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingNewType = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(WaterLogTheme.accent)
                    }
                    .accessibilityLabel("New drink type")
                }
            }
            .sheet(isPresented: $isPresentingNewType) {
                AddDrinkTypeSheet(appModel: appModel)
            }
        }
    }
}
