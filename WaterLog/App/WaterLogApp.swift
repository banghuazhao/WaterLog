//
// Created by Banghua Zhao on 19/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import SQLiteData
import SwiftUI

@main
struct WaterLogApp: App {
  @State private var appModel: AppModel

  init() {
    AdMobBootstrap.startIfNeeded()
    prepareDependencies {
      $0.defaultDatabase = try! AppDatabase.makeDatabaseQueue()
    }
    _appModel = State(initialValue: AppModel())
  }

  var body: some Scene {
    WindowGroup {
      ContentView(appModel: appModel)
    }
  }
}
