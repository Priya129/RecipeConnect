import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

import '../routes/routes.dart';

class InterstitialAdManager {
  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  BuildContext? _context;

  void initializeInterstitialAd(BuildContext context) {
    _context = context;
    _loadInterstitialAd();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: getInterstitialAdUnitId()!,
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
          _interstitialAd!.setImmersiveMode(true);
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              ad.dispose();
              _isAdLoaded = false;
              _loadInterstitialAd(); // Reload ad after dismissal
              if (_context != null) {
                Routes().navigateToMainPage(_context!);
              }
            },
            onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
              ad.dispose();
              _isAdLoaded = false;
              _loadInterstitialAd(); // Reload ad on failure
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('InterstitialAd failed to load: $error');
          _isAdLoaded = false;
        },
      ),
    );
  }

  Future<void> showInterstitialAd(BuildContext context) async {
    if (_isAdLoaded && _interstitialAd != null) {
      _interstitialAd!.show();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ad is still loading. Please wait.')),
      );
      await Future.delayed(Duration(seconds: 1));
      if (!_isAdLoaded) {
        print('Ad is still not loaded after waiting.');
      }
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
  }

  String? getInterstitialAdUnitId() {
    if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910'; // Test ID for iOS
    } else if (Platform.isAndroid) {
      return 'ca-app-pub-2850266641030338/1433179476'; // Replace with your actual Ad Unit ID
    }
    return null;
  }
}
