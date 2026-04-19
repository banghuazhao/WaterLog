//
// Created by Banghua Zhao on 19/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct ContentView: View {
  @Bindable var appModel: AppModel
  @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
  @State private var showOnboarding = false

  var body: some View {
    MainTabView(appModel: appModel)
      .onAppear {
        if !hasCompletedOnboarding {
          showOnboarding = true
        }
      }
      .onChange(of: showOnboarding) { _, isShowing in
        if !isShowing && !hasCompletedOnboarding {
          hasCompletedOnboarding = true
        }
      }
      .fullScreenCover(isPresented: $showOnboarding) {
        OnboardingView(appModel: appModel) {
          hasCompletedOnboarding = true
          showOnboarding = false
        }
      }
      .alert("Something went wrong", isPresented: errorPresented) {
        Button("OK", role: .cancel) {
          appModel.clearUserFacingError()
        }
      } message: {
        Text(appModel.userFacingError ?? "")
      }
  }

  private var errorPresented: Binding<Bool> {
    Binding(
      get: { appModel.userFacingError != nil },
      set: { if !$0 { appModel.clearUserFacingError() } }
    )
  }
}
