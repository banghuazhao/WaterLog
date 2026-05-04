//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
  

enum AdMobBannerConfiguration {
  /// Banner ad unit from Info.plist (`bannerViewAdUnitID`), set per configuration in `Debug.xcconfig` / `Release.xcconfig`.
  static let adaptiveBannerAdUnitID = Bundle.main.object(forInfoDictionaryKey: "bannerViewAdUnitID") as? String ?? ""
}
