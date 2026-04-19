//
// Created by Banghua Zhao on 19/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import Observation

@Observable @MainActor
final class SettingsViewModel {
  let appModel: AppModel

  init(appModel: AppModel) {
    self.appModel = appModel
  }
}
