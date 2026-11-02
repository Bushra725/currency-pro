import GoogleMobileAds
import UIKit
import google_mobile_ads

/// Native ad layout whose MediaView is at least 120x120 pt (AdMob iOS video minimum).
final class CurrencyNativeAdFactory: NSObject, FLTNativeAdFactory {
  private static let mediaMin: CGFloat = 120

  func createNativeAd(
    _ nativeAd: NativeAd,
    customOptions: [AnyHashable: Any]? = nil
  ) -> NativeAdView? {
    let adView = NativeAdView()
    adView.backgroundColor = .clear
    adView.translatesAutoresizingMaskIntoConstraints = false

    let mediaView = MediaView()
    mediaView.translatesAutoresizingMaskIntoConstraints = false
    mediaView.contentMode = .scaleAspectFill
    mediaView.clipsToBounds = true
    mediaView.layer.cornerRadius = 12
    adView.addSubview(mediaView)
    adView.mediaView = mediaView

    let headline = UILabel()
    headline.translatesAutoresizingMaskIntoConstraints = false
    headline.font = .systemFont(ofSize: 15, weight: .semibold)
    headline.numberOfLines = 2
    adView.addSubview(headline)
    adView.headlineView = headline

    let body = UILabel()
    body.translatesAutoresizingMaskIntoConstraints = false
    body.font = .systemFont(ofSize: 12)
    body.textColor = .secondaryLabel
    body.numberOfLines = 2
    adView.addSubview(body)
    adView.bodyView = body

    let cta = UIButton(type: .system)
    cta.translatesAutoresizingMaskIntoConstraints = false
    cta.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
    cta.backgroundColor = .systemBlue
    cta.setTitleColor(.white, for: .normal)
    cta.layer.cornerRadius = 8
    cta.isUserInteractionEnabled = false
    adView.addSubview(cta)
    adView.callToActionView = cta

    let icon = UIImageView()
    icon.translatesAutoresizingMaskIntoConstraints = false
    icon.contentMode = .scaleAspectFit
    icon.clipsToBounds = true
    icon.layer.cornerRadius = 6
    adView.addSubview(icon)
    adView.iconView = icon

    let adChoices = AdChoicesView()
    adChoices.translatesAutoresizingMaskIntoConstraints = false
    adView.addSubview(adChoices)
    adView.adChoicesView = adChoices

    NSLayoutConstraint.activate([
      mediaView.topAnchor.constraint(equalTo: adView.topAnchor, constant: 8),
      mediaView.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 8),
      mediaView.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -8),
      mediaView.widthAnchor.constraint(greaterThanOrEqualToConstant: Self.mediaMin),
      mediaView.heightAnchor.constraint(equalToConstant: 200),

      icon.topAnchor.constraint(equalTo: mediaView.bottomAnchor, constant: 8),
      icon.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 8),
      icon.widthAnchor.constraint(equalToConstant: 36),
      icon.heightAnchor.constraint(equalToConstant: 36),

      headline.topAnchor.constraint(equalTo: icon.topAnchor),
      headline.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 8),
      headline.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -8),

      body.topAnchor.constraint(equalTo: headline.bottomAnchor, constant: 2),
      body.leadingAnchor.constraint(equalTo: headline.leadingAnchor),
      body.trailingAnchor.constraint(equalTo: headline.trailingAnchor),

      cta.topAnchor.constraint(greaterThanOrEqualTo: icon.bottomAnchor, constant: 8),
      cta.topAnchor.constraint(greaterThanOrEqualTo: body.bottomAnchor, constant: 8),
      cta.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 8),
      cta.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -8),
      cta.heightAnchor.constraint(equalToConstant: 36),
      cta.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -8),

      adChoices.topAnchor.constraint(equalTo: adView.topAnchor, constant: 8),
      adChoices.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -8),
    ])

    headline.text = nativeAd.headline
    body.text = nativeAd.body
    body.isHidden = nativeAd.body == nil
    cta.setTitle(nativeAd.callToAction, for: .normal)
    cta.isHidden = nativeAd.callToAction == nil
    icon.image = nativeAd.icon?.image
    icon.isHidden = nativeAd.icon == nil
    mediaView.mediaContent = nativeAd.mediaContent

    adView.nativeAd = nativeAd
    return adView
  }
}
