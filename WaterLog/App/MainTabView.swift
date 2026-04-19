//
// Created by Banghua Zhao on 19/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct MainTabView: View {
  @Bindable var appModel: AppModel
  @State private var homeViewModel: HomeViewModel
  @State private var reportViewModel: ReportViewModel
  @State private var settingsViewModel: SettingsViewModel

  init(appModel: AppModel) {
    self.appModel = appModel
    _homeViewModel = State(wrappedValue: HomeViewModel(appModel: appModel))
    _reportViewModel = State(wrappedValue: ReportViewModel(appModel: appModel))
    _settingsViewModel = State(wrappedValue: SettingsViewModel(appModel: appModel))
  }

  var body: some View {
    TabView {
      HomeView(homeViewModel: homeViewModel)
        .tabItem {
          Label("Home", systemImage: "drop.fill")
        }

      DrinksListView(appModel: appModel)
        .tabItem {
          Label("Drinks", systemImage: "cup.and.saucer.fill")
        }

      ReportView(reportViewModel: reportViewModel)
        .tabItem {
          Label("Report", systemImage: "chart.xyaxis.line")
        }

      SettingsView(settingsViewModel: settingsViewModel)
        .tabItem {
          Label("Settings", systemImage: "gearshape.fill")
        }
    }
    .tint(WaterLogTheme.accent)
  }
}
