import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../main.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../component/AdMobComponent.dart';
import '../component/FacebookAdsComponent.dart';
import 'constant.dart';
import 'loader.dart';

Color hexStringToHexInt(String hex) {
  hex = hex.replaceFirst('#', '');
  hex = hex.length == 6 ? 'ff' + hex : hex;
  int val = int.parse(hex, radix: 16);
  return Color(val);
}

launchURLString(String openUrl) async {
  if (await canLaunchUrl(Uri.parse(openUrl))) {
    await launchUrl(Uri.parse(openUrl), mode: LaunchMode.externalApplication);
  } else {
    throw 'Could not launch $openUrl';
  }
}

class CustomTheme extends StatelessWidget {
  final Widget? child;

  CustomTheme({this.child});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: appStore.isDarkModeOn!
          ? ThemeData.dark().copyWith(
              colorScheme: ColorScheme.fromSwatch().copyWith(secondary: appStore.primaryColors),
            )
          : ThemeData.light(),
      child: child!,
    );
  }
}

String? getReferralCodeFromNative() {
  const platform = const MethodChannel('mightyweb/channel');

  if (isMobile) {
    var referralCode = platform.invokeMethod('mightyweb/events');

    return referralCode.toString();
  } else {
    return '';
  }
}

Future<bool> checkWebRTCPermission() async {
  await Permission.microphone.request();
  await Permission.camera.request();
  if (Platform.isAndroid) {
    final status = await Permission.microphone.status;
    final status1 = await Permission.camera.status;
    if (status != PermissionStatus.granted && status1 != PermissionStatus.granted) {
      final result = await Permission.microphone.request();
      final result1 = await Permission.camera.request();
      if (result == PermissionStatus.granted && result1 == PermissionStatus.granted) {
        if (getStringAsync(IS_LOADER) == "true") appStore.setLoading(true);
        return true;
      }
    } else {
      return true;
    }
  } else {
    return true;
  }
  return false;
}

///  HttpOverrides.global = HttpOverridesSkipCertificate();
class HttpOverridesSkipCertificate extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => super.createHttpClient(context)..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
}

Widget itemWidget(BuildContext context, {required Function onTap, int code = 0, String? data1, bool? isColor}) {
  return Container(
    height: 70,
    width: context.width() * 0.199,
    decoration: boxDecorationWithShadow(borderRadius: radius(8), backgroundColor: Theme.of(context).cardTheme.color!),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 80,
          decoration: boxDecorationWithShadow(borderRadius: radius(8), backgroundColor: isColor == false ? Theme.of(context).cardTheme.color! : hexStringToHexInt(data1!)),
          padding: EdgeInsets.all(16),
          child: Loaders(name: data1),
        ),
        if (isColor == false)
          AnimatedContainer(
            decoration: boxDecorationWithRoundedCorners(
              borderRadius: radius(8),
              backgroundColor: getIntAsync(LOADER_VARIANT, defaultValue: 0) == code ? Colors.black38 : Colors.transparent,
            ),
            duration: Duration(milliseconds: 800),
          ),
        Align(
          alignment: Alignment.center,
          child: AnimatedContainer(
            padding: EdgeInsets.all(4),
            duration: Duration(milliseconds: 800),
            child: Icon(Icons.check, size: 18, color: appStore.primaryColors),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: defaultBoxShadow()),
          ).visible(getIntAsync(LOADER_VARIANT, defaultValue: 0) == code || getIntAsync(THEME_VARIANT, defaultValue: 0) == code),
        ),
      ],
    ).onTap(() async {
      onTap.call();
    }),
  );
}

void loadInterstitialAds() {
  getStringAsync(ADD_TYPE) != NONE
      ? getStringAsync(ADD_TYPE) == isGoogleAds
          ? createInterstitialAd()
          : loadFacebookInterstitialAd()
      : SizedBox();
}

void showInterstitialAds() {
  getStringAsync(ADD_TYPE) != NONE
      ? getStringAsync(ADD_TYPE) == isGoogleAds
          ? adShow()
          : showFacebookInterstitialAd()
      : SizedBox();
}

Widget showBannerAds() {
  //return loadFacebookBannerId();
  return getStringAsync(ADD_TYPE) != NONE
      ? getStringAsync(ADD_TYPE) == isGoogleAds
          ? Container(
              height: 60,
              child: AdWidget(
                ad: BannerAd(
                  adUnitId: kReleaseMode
                      ? getBannerAdUnitId()!
                      : Platform.isIOS
                          ? getStringAsync(AD_MOB_BANNER_ID_IOS)
                          : getStringAsync(AD_MOB_BANNER_ID),
                  size: AdSize.banner,
                  request: AdRequest(),
                  listener: BannerAdListener(),
                )..load(),
              ),
            )
          : loadFacebookBannerId()
      : SizedBox();
}
