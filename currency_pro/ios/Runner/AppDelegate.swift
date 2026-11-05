import AppTrackingTransparency
import Flutter
import UIKit
import google_mobile_ads

enum AdsTracking {
  static func request(_ completion: @escaping (Int) -> Void) {
    DispatchQueue.main.async {
      if #available(iOS 14, *) {
        ATTrackingManager.requestTrackingAuthorization { status in
          completion(Int(status.rawValue))
        }
      } else {
        completion(3)
      }
    }
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
      engineBridge.pluginRegistry,
      factoryId: "native_media",
      nativeAdFactory: CurrencyNativeAdFactory()
    )
    let messenger = engineBridge.pluginRegistry
      .registrar(forPlugin: "CurrencyProNative")!
      .messenger()
    registerLinks(messenger)
    registerHaptics(messenger)
    registerAds(messenger)
  }

  private func registerAds(_ messenger: FlutterBinaryMessenger) {
    FlutterMethodChannel(
      name: "com.theoccess.currencypro/ads",
      binaryMessenger: messenger
    ).setMethodCallHandler { call, result in
      guard call.method == "requestTracking" else {
        result(FlutterMethodNotImplemented)
        return
      }
      AdsTracking.request { status in
        result(status)
      }
    }
  }

  private func registerLinks(_ messenger: FlutterBinaryMessenger) {
    FlutterMethodChannel(
      name: "com.theoccess.currencypro/links",
      binaryMessenger: messenger
    ).setMethodCallHandler { call, result in
      guard call.method == "openUrl" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let raw = call.arguments as? String, let url = URL(string: raw) else {
        result(false)
        return
      }
      UIApplication.shared.open(url, options: [:]) { ok in
        result(ok)
      }
    }
  }

  private func registerHaptics(_ messenger: FlutterBinaryMessenger) {
    FlutterMethodChannel(
      name: "com.theoccess.currencypro/haptics",
      binaryMessenger: messenger
    ).setMethodCallHandler { call, result in
      guard call.method == "tick" else {
        result(FlutterMethodNotImplemented)
        return
      }
      let generator = UIImpactFeedbackGenerator(style: .medium)
      generator.prepare()
      generator.impactOccurred()
      result(nil)
    }
  }
}
