import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Kept alive so a tick is not dropped while the generator is warming up.
  /// UIImpactFeedbackGenerator is available on every iPhone this app supports,
  /// including models older than iPhone 14.
  private let haptic = UIImpactFeedbackGenerator(style: .heavy)

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let messenger = engineBridge.applicationRegistrar.messenger()

    FlutterMethodChannel(
      name: "com.theoccess.currencypro/haptics",
      binaryMessenger: messenger
    ).setMethodCallHandler { [weak self] call, result in
      guard call.method == "tick" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.haptic.prepare()
      self?.haptic.impactOccurred()
      result(nil)
    }

    FlutterMethodChannel(
      name: "com.theoccess.currencypro/links",
      binaryMessenger: messenger
    ).setMethodCallHandler { call, result in
      guard call.method == "openUrl" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let urlString = call.arguments as? String,
            let url = URL(string: urlString) else {
        result(false)
        return
      }
      UIApplication.shared.open(url, options: [:]) { opened in
        result(opened)
      }
    }
  }
}
