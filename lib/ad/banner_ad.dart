import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

class LargeBannerAd extends StatefulWidget {
  @override
  _LargeBannerAdState createState() => _LargeBannerAdState();
}

class _LargeBannerAdState extends State<LargeBannerAd> {
  late BannerAd _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _bannerAd = BannerAd(
      adUnitId: getBannerAdUnitId()!,
      size: AdSize.largeBanner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          print('BannerAd failed to load: $error');
        },
      ),
    );

    _bannerAd.load();
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isAdLoaded
        ? Container(
      height: _bannerAd.size.height.toDouble(),
      width: _bannerAd.size.width.toDouble(),
      child: AdWidget(ad: _bannerAd),
    )
        : SizedBox.shrink();
  }

  String? getBannerAdUnitId() {
    if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    } else if (Platform.isAndroid) {
      return 'ca-app-pub-2850266641030338/4654239189';
    }
    return null;
  }
}
