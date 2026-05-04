//
// Created by Banghua Zhao on 24/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import GoogleMobileAds
import SwiftUI
import UIKit


private final class WaterLogBannerDelegate: NSObject, BannerViewDelegate {
  weak var host: AdaptiveListBannerHostView?

  func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
    #if DEBUG
      print("WaterLog AdMob banner failed:", error.localizedDescription)
    #endif
  }

  func bannerViewDidReceiveAd(_ bannerView: BannerView) {
    host?.bannerFinishedLoading()
  }
}

/// Inline adaptive `BannerView` for scrollable lists (Drinks / Settings). Width changes reload; height is capped.
final class AdaptiveListBannerHostView: UIView {
  private let banner = BannerView()
  private let loadDelegate = WaterLogBannerDelegate()
  private var lastRequestedWidth: CGFloat = 0
  private var configuredAdUnitID: String = AdMobBannerConfiguration.adaptiveBannerAdUnitID
  /// Caps inline adaptive height; smaller values keep list footers compact (e.g. Drinks vs Settings).
  private var maxInlineBannerHeight: CGFloat = 120

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    clipsToBounds = true
    loadDelegate.host = self
    banner.delegate = loadDelegate
    banner.translatesAutoresizingMaskIntoConstraints = false
    addSubview(banner)
    NSLayoutConstraint.activate([
      banner.centerXAnchor.constraint(equalTo: centerXAnchor),
      banner.topAnchor.constraint(equalTo: topAnchor),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(adUnitID: String, maxInlineBannerHeight: CGFloat) {
    let idChanged = adUnitID != configuredAdUnitID
    let heightChanged = maxInlineBannerHeight != self.maxInlineBannerHeight
    configuredAdUnitID = adUnitID
    self.maxInlineBannerHeight = maxInlineBannerHeight
    banner.adUnitID = adUnitID
    if idChanged || heightChanged { lastRequestedWidth = 0 }
    invalidateIntrinsicContentSize()
    setNeedsLayout()
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()
    attachRootViewControllerIfPossible()
  }

  override var intrinsicContentSize: CGSize {
    guard !configuredAdUnitID.isEmpty else {
      return CGSize(width: UIView.noIntrinsicMetric, height: 0)
    }
    let width = contentWidthForSizing
    let adSize = inlineAdaptiveBanner(width: width, maxHeight: maxInlineBannerHeight)
    return CGSize(width: UIView.noIntrinsicMetric, height: adSize.size.height)
  }

  private var contentWidthForSizing: CGFloat {
    if bounds.width > 50 { return bounds.width }
    let screenWidth = window?.windowScene?.screen.bounds.width ?? UIScreen.main.bounds.width
    return max(320, screenWidth - 32)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    attachRootViewControllerIfPossible()

    let width = bounds.width > 50 ? bounds.width : contentWidthForSizing
    guard width > 50 else { return }

    if abs(width - lastRequestedWidth) < 0.5 { return }
    lastRequestedWidth = width

    guard !configuredAdUnitID.isEmpty else { return }

    let adSize = inlineAdaptiveBanner(width: width, maxHeight: maxInlineBannerHeight)
    banner.adSize = adSize
    banner.load(Request())
    invalidateIntrinsicContentSize()
  }

  fileprivate func bannerFinishedLoading() {
    invalidateIntrinsicContentSize()
  }

  private func attachRootViewControllerIfPossible() {
    guard let root = window?.rootViewController?.wl_topMostVisible else { return }
    banner.rootViewController = root
  }
}

struct WaterLogListEmbeddedBannerView: UIViewRepresentable {
  var adUnitID: String = AdMobBannerConfiguration.adaptiveBannerAdUnitID
  /// Inline adaptive max height; default matches previous app-wide cap. Use a lower value for a shorter banner row.
  var maxInlineBannerHeight: CGFloat = 120

  func makeUIView(context: Context) -> AdaptiveListBannerHostView {
    let view = AdaptiveListBannerHostView()
    view.configure(adUnitID: adUnitID, maxInlineBannerHeight: maxInlineBannerHeight)
    return view
  }

  func updateUIView(_ uiView: AdaptiveListBannerHostView, context: Context) {
    uiView.configure(adUnitID: adUnitID, maxInlineBannerHeight: maxInlineBannerHeight)
  }
}

private extension UIViewController {
  var wl_topMostVisible: UIViewController {
    if let nav = self as? UINavigationController, let visible = nav.visibleViewController {
      return visible.wl_topMostVisible
    }
    if let tab = self as? UITabBarController, let selected = tab.selectedViewController {
      return selected.wl_topMostVisible
    }
    if let presented = presentedViewController {
      return presented.wl_topMostVisible
    }
    return self
  }
}
