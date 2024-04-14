// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// ignore_for_file: public_member_api_docs

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'constants.dart';

/// This example demonstrates inline adaptive banner ads.
///
/// Loads and shows an inline adaptive banner ad in a scrolling view,
/// and reloads the ad when the orientation changes.
class AdBannerAnimatedExample extends StatelessWidget {
  const AdBannerAnimatedExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ad Banner Animated Example'),
      ),
      body: Center(
        child: ListView.separated(
          itemCount: 3,
          separatorBuilder: (context, index) => SizedBox(height: 40),
          itemBuilder: (BuildContext context, int index) {
            if (index == 0) {
              return const AdBannerExample(
                padding: EdgeInsets.symmetric(horizontal: 16),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                Constants.placeholderText,
                style: TextStyle(fontSize: 24),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AdBannerExample extends StatefulWidget {
  const AdBannerExample({
    Key? key,
    required this.padding,
  }) : super(key: key);

  final EdgeInsets padding;

  @override
  State<AdBannerExample> createState() => _AdBannerExampleState();
}

class _AdBannerExampleState extends State<AdBannerExample> {
  AdManagerBannerAd? _banner;
  double _height = 1;
  double _width = 1;

  /// used to change [_height] only when ad is impressed.
  /// to avoid changing [_height] when ad is loaded but not impressed
  double temporaryHeight = 0;

  /// used to change [_width] only when ad is impressed.
  /// to assign the correct width to the ad
  double temporaryWidth = 0;

  EdgeInsets get padding => widget.padding;
  double get horizontalPaddings =>
      [padding.left, padding.right].reduce((a, b) => a + b);

  static const adsCommonHeight = 100.0;
  static const animationDuration = Duration(milliseconds: 1500);

  double get _adWidth => MediaQuery.sizeOf(context).width - horizontalPaddings;

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBanner();
    });
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  Future<void> _loadBanner() async {
    AdSize size = AdSize.getCurrentOrientationInlineAdaptiveBannerAdSize(
      _adWidth.truncate(),
    );

    await AdManagerBannerAd(
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/9214589741'
          : 'ca-app-pub-3940256099942544/2435281174',
      sizes: [size],
      request: AdManagerAdRequest(),
      listener: AdManagerBannerAdListener(
        onAdLoaded: (Ad ad) async {
          final bannerAd = ad as AdManagerBannerAd;

          try {
            final size = await bannerAd.getPlatformAdSize();
            temporaryHeight = size?.height.toDouble() ?? adsCommonHeight;
            temporaryWidth = size?.width.toDouble() ?? _adWidth;
          } catch (e) {
            temporaryHeight = adsCommonHeight;
            temporaryWidth = _adWidth;
            debugPrint('Banner error inside onAdLoaded: $e');
          }

          setState(() {
            _banner = bannerAd;
          });
        },
        onAdImpression: (Ad ad) {
          debugPrint('Banner onAdImpression');
          setState(() {
            _height = temporaryHeight;
            _width = temporaryWidth;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint(' Failed to load with code: ${error.toString()}');
          ad.dispose();
        },
      ),
    ).load();
  }

  @override
  Widget build(BuildContext context) {
    if (_banner == null) {
      return SizedBox();
    }

    final _adWidget = Padding(
      padding: widget.padding,
      child: SizedBox(
        width: _width,
        height: _height,
        child: AdWidget(
          ad: _banner!,
        ),
      ),
    );

    /// Stack and Padding previously for iOS to prevent rebuilds and ensure
    /// that it works as expected.
    if (Platform.isIOS) {
      return Stack(
        alignment: Alignment.center,
        fit: StackFit.loose,
        clipBehavior: Clip.none,
        children: [
          AnimatedSize(
            duration: animationDuration,
            child: _adWidget,
          ),
        ],
      );
    }

    return AnimatedSize(
      duration: animationDuration,
      child: _adWidget,
    );
  }
}
