import GoogleMobileAds
import UIKit
import google_mobile_ads

/// Native ad layout whose MediaView has a real 120×120+ pt frame *before*
/// `nativeAd` is assigned. AdMob's video validator reads `bounds` at that
/// moment, so Auto Layout constraints alone are still reported as 0×0.
final class CurrencyNativeAdFactory: NSObject, FLTNativeAdFactory {
  private static let mediaMin: CGFloat = 120
  private static let mediaHeight: CGFloat = 200
  private static let cardWidth: CGFloat = 360
  private static let cardHeight: CGFloat = 355

  func createNativeAd(
    _ nativeAd: NativeAd,
    customOptions: [AnyHashable: Any]? = nil
  ) -> NativeAdView? {
    let adView = NativeAdView(
      frame: CGRect(x: 0, y: 0, width: Self.cardWidth, height: Self.cardHeight)
    )
    adView.backgroundColor = .clear
    adView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    adView.translatesAutoresizingMaskIntoConstraints = true

    let mediaView = MediaView(
      frame: CGRect(
        x: 12,
        y: 12,
        width: Self.cardWidth - 24,
        height: Self.mediaHeight
      )
    )
    mediaView.autoresizingMask = [.flexibleWidth]
    mediaView.translatesAutoresizingMaskIntoConstraints = true
    mediaView.contentMode = .scaleAspectFill
    mediaView.clipsToBounds = true
    mediaView.layer.cornerRadius = 12
    adView.addSubview(mediaView)
    adView.mediaView = mediaView

    let icon = UIImageView(frame: CGRect(x: 12, y: 224, width: 40, height: 40))
    icon.contentMode = .scaleAspectFit
    icon.clipsToBounds = true
    icon.layer.cornerRadius = 6
    adView.addSubview(icon)
    adView.iconView = icon

    let headline = UILabel(frame: CGRect(x: 60, y: 222, width: 288, height: 20))
    headline.autoresizingMask = [.flexibleWidth]
    headline.font = .systemFont(ofSize: 15, weight: .semibold)
    headline.numberOfLines = 1
    adView.addSubview(headline)
    adView.headlineView = headline

    let body = UILabel(frame: CGRect(x: 60, y: 242, width: 288, height: 18))
    body.autoresizingMask = [.flexibleWidth]
    body.font = .systemFont(ofSize: 12)
    body.textColor = .secondaryLabel
    body.numberOfLines = 1
    adView.addSubview(body)
    adView.bodyView = body

    let cta = UIButton(
      frame: CGRect(x: 12, y: 307, width: Self.cardWidth - 24, height: 36)
    )
    cta.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
    cta.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
    cta.backgroundColor = .systemBlue
    cta.setTitleColor(.white, for: .normal)
    cta.layer.cornerRadius = 8
    cta.isUserInteractionEnabled = false
    adView.addSubview(cta)
    adView.callToActionView = cta

    let adChoices = AdChoicesView(frame: CGRect(x: 325, y: 8, width: 20, height: 20))
    adChoices.autoresizingMask = [.flexibleLeftMargin]
    adView.addSubview(adChoices)
    adView.adChoicesView = adChoices

    headline.text = nativeAd.headline
    body.text = nativeAd.body
    body.isHidden = nativeAd.body == nil
    cta.setTitle(nativeAd.callToAction, for: .normal)
    cta.isHidden = nativeAd.callToAction == nil
    icon.image = nativeAd.icon?.image
    icon.isHidden = nativeAd.icon == nil
    mediaView.mediaContent = nativeAd.mediaContent

    // Validator reads MediaView.bounds here. Force a laid-out frame first.
    adView.layoutIfNeeded()
    if mediaView.bounds.width < Self.mediaMin ||
        mediaView.bounds.height < Self.mediaMin {
      mediaView.frame = CGRect(
        x: 12,
        y: 12,
        width: max(mediaView.bounds.width, Self.cardWidth - 24),
        height: max(mediaView.bounds.height, Self.mediaHeight)
      )
    }
    adView.nativeAd = nativeAd
    return adView
  }
}
