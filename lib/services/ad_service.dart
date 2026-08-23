import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static RewardedAd? _rewardedAd;
  static InterstitialAd? _interstitialAd;

  // Test Ad Unit IDs
  static final String _rewardedAdUnitId = defaultTargetPlatform == TargetPlatform.iOS
      ? 'ca-app-pub-3940256099942544/1712485313'
      : 'ca-app-pub-5028375165405410/2454403057';

  static final String _interstitialAdUnitId = defaultTargetPlatform == TargetPlatform.iOS
      ? 'ca-app-pub-3940256099942544/4411468910'
      : 'ca-app-pub-5028375165405410/6745001851';

  static void loadRewardedAd() {
    if (kIsWeb) return;
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedAd failed to load: $error');
          _rewardedAd = null;
        },
      ),
    );
  }

  static void loadInterstitialAd() {
    if (kIsWeb) return;
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: $error');
          _interstitialAd = null;
        },
      ),
    );
  }

  /// Shows a rewarded ad. If not loaded, immediately invokes the callback.
  static void showRewardedAd(void Function() onUserEarnedReward) {
    if (kIsWeb) {
      onUserEarnedReward();
      return;
    }
    if (_rewardedAd != null) {
      _rewardedAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem rewardItem) {
        onUserEarnedReward();
      });
      _rewardedAd = null; // Consume ad
      loadRewardedAd(); // Load next
    } else {
      // Fallback if ad failed to load, just continue the flow
      onUserEarnedReward();
      loadRewardedAd(); // Attempt to load again
    }
  }

  /// Shows an interstitial ad.
  static void showInterstitialAd() {
    if (kIsWeb) return;
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null; // Consume ad
      loadInterstitialAd(); // Load next
    } else {
      loadInterstitialAd(); // Attempt to load again
    }
  }
}
