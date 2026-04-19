//
// Created by Banghua Zhao on 19/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct ContentView: View {
  @Bindable var appModel: AppModel

  var body: some View {
    MainTabView(appModel: appModel)
  }
}
