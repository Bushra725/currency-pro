import Flutter
import UIKit
import google_mobile_ads

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
