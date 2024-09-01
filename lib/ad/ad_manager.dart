import 'package:flutter/material.dart';
import 'banner_ad.dart';
import 'interstitial_ad.dart';

class AdManager {
  final InterstitialAdManager interstitialAdManager = InterstitialAdManager();
  final LargeBannerAd _largeBannerAd = LargeBannerAd();

  void initializeAds(BuildContext context) {
    interstitialAdManager.initializeInterstitialAd(context);
  }

  void showInterstitialAd(BuildContext context) {
    interstitialAdManager.showInterstitialAd(context);
  }

  void disposeAds() {
    interstitialAdManager.dispose();
  }

  Widget getLargeBannerAdWidget() {
    return _largeBannerAd;
  }
}
