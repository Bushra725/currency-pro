import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  private var didAskTracking = false

  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    guard !didAskTracking else { return }
    didAskTracking = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
      AdsTracking.request { _ in }
    }
  }
}
