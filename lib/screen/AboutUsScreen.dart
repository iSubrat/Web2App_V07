
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import '../app_localizations.dart';
import '../main.dart';
import '../utils/AppWidget.dart';
import '../utils/colors.dart';
import '../utils/common.dart';
import '../utils/constant.dart';
import '../utils/images.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutUsScreen extends StatefulWidget {
  static String tag = '/AboutUsScreen';

  @override
  AboutUsScreenState createState() => AboutUsScreenState();
}

class AboutUsScreenState extends State<AboutUsScreen> {

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Widget mSocialOption(var value, {var color}) {
    return Image.asset(value, height: 30, width: 30, color: color).paddingAll(8);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var appLocalization = AppLocalizations.of(context)!;
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        // HomeScreen().launch(context);
        return true;
      },
      child: Scaffold(
        backgroundColor: context.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: appStore.primaryColors,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  getColorFromHex(getStringAsync(GRADIENT1), defaultColor: primaryColor1),
                  getColorFromHex(getStringAsync(GRADIENT2), defaultColor: primaryColor1),
                ],
              ),
            ),
          ).visible(getStringAsync(THEME_STYLE) == THEME_STYLE_GRADIENT),
          title: Text(appLocalization.translate('lbl_about_us')!, style: boldTextStyle(color: white, size: 18)),
          leading: IconButton(
            icon: Icon(Icons.chevron_left_sharp, color: white),
            onPressed: () {
              Navigator.pop(context);
              //   HomeScreen().launch(context);
            },
          ),
          elevation: 0,
        ),
        bottomNavigationBar: Container(
          height: 110,
          child: Column(
            children: [
              Text(appLocalization.translate('lbl_follow_us')!, style: primaryTextStyle()),
              4.height,
              SizedBox(
                height: 55,
                child: ListView(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        mSocialOption(ic_skype)
                            .onTap(() {
                              launchURLString(getStringAsync(SKYPE));
                            })
                            .paddingOnly(left: 16, right: 16)
                            .visible(getStringAsync(SKYPE).isNotEmpty),
                        mSocialOption(ic_snapchat)
                            .onTap(() {
                              launchURLString(getStringAsync(SNAPCHAT));
                            })
                            .paddingRight(16)
                            .visible(getStringAsync(SNAPCHAT).isNotEmpty),
                        mSocialOption(ic_youtube)
                            .onTap(() {
                              launchURLString(getStringAsync(YOUTUBE));
                            })
                            .paddingRight(16)
                            .visible(getStringAsync(YOUTUBE).isNotEmpty),
                        mSocialOption(ic_messenger)
                            .onTap(() {
                              launchURLString(getStringAsync(MESSENGER));
                            })
                            .paddingRight(16)
                            .visible(getStringAsync(MESSENGER).isNotEmpty),
                        mSocialOption(icoWhatsApp)
                            .onTap(() {
                              if (isIOS) {
                                var whatsappUrl = "https://api.whatsapp.com/send?phone=${getStringAsync(WHATS_APP_NUMBER)}";
                                launchURLString(whatsappUrl);
                              } else {
                                var whatsappUrl = "https://whatsapp://send?phone=${getStringAsync(WHATS_APP_NUMBER)}";
                                launchURLString(whatsappUrl);
                              }
                            })
                            .paddingRight(16)
                            .visible(getStringAsync(WHATS_APP_NUMBER).isNotEmpty),
                        mSocialOption(icoInstaGram)
                            .onTap(() {
                              launchURLString(getStringAsync(INSTA_GRAM_URL));
                            })
                            .paddingRight(16)
                            .visible(getStringAsync(INSTA_GRAM_URL).isNotEmpty),
                        mSocialOption(icoTwitter)
                            .onTap(() {
                              launchURLString(getStringAsync(TWITTER_URL));
                            })
                            .paddingRight(16)
                            .visible(getStringAsync(TWITTER_URL).isNotEmpty),
                        mSocialOption(icoFacebook)
                            .onTap(() {
                              launchURLString(getStringAsync(FACEBOOK_URL));
                            })
                            .paddingRight(16)
                            .visible(getStringAsync(FACEBOOK_URL).isNotEmpty),
                        mSocialOption(icoCall, color: appStore.primaryColors)
                            .onTap(() {
                              var call = getStringAsync(
                                CALL_NUMBER,
                              );
                              launchURLString("tel:$call");
                            })
                            .paddingRight(16)
                            .visible(getStringAsync(CALL_NUMBER).isNotEmpty),
                      ],
                    ),
                  ],
                ),
              ),
              Text(getStringAsync(COPYRIGHT), style: secondaryTextStyle(), maxLines: 1),
            ],
          ),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            cachedImage(getStringAsync(APPLOGO), width: 100, height: 100).cornerRadiusWithClipRRect(10),
            16.height,
            Text(getStringAsync(APPNAME), style: boldTextStyle(size: 22)),
            4.height,
            Text(getStringAsync(DESCRIPTION), style: primaryTextStyle(size: 14), textAlign: TextAlign.center).paddingOnly(left: 16, right: 16),
            2.height,
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (_, snap) {
                if (snap.hasData) {
                  return Text('V ${snap.data!.version.validate()}', style: secondaryTextStyle());
                }
                return SizedBox();
              },
            ),
          ],
        ).center(),
      ),
    );
  }
}
