import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import '../main.dart';
import '../model/MainResponse.dart' as model;
import '../model/MainResponse.dart';
import '../utils/colors.dart';
import '../utils/common.dart';
import '../utils/constant.dart';
import 'package:nb_utils/nb_utils.dart';

Future handleResponse(Response response) async {
  if (!await isNetworkAvailable()) {
    throw errorInternetNotAvailable;
  }

  if (response.statusCode.isSuccessful()) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  } else {
    try {
      var body = jsonDecode(response.body);
      throw body['message'];
    } on Exception catch (e) {
      log(e);
      throw errorSomethingWentWrong;
    }
  }
}

Map<String, String> buildHeaderTokens() {
  Map<String, String> header = {
    HttpHeaders.contentTypeHeader: 'text/html; charset=utf-8',
  };

  log(jsonEncode(header));
  return header;
}

Future<model.MainResponse> fetchData() async {
  final response;
  if (PURCHASE_CODE.isEmpty) {
    log("BASE_URL" + BASE_URL);
    response = await http.Client().get(Uri.parse(BASE_URL + '/upload/mightyweb.json'));
  } else {
    response = await http.Client().get(Uri.parse(BASE_URL_OFFLINE));
  }

  return await handleResponse(response).then((json1) async {
    var mModel = model.MainResponse.fromJson(json1);
    if (mModel != null) {
      // App Configuration
      if (mModel.appconfiguration != null) {
        await setValue(APPNAME, mModel.appconfiguration!.appName);
        await setValue(URL, mModel.appconfiguration!.url.isEmptyOrNull ? 'https://www.google.com' : mModel.appconfiguration!.url);
        await setValue(APP_LANGUAGE, mModel.appconfiguration!.appLanuguage);
        await appStore.setLanguage(mModel.appconfiguration!.appLanuguage);
        await setValue(IS_SPLASH_SCREEN, mModel.appconfiguration!.isSplashScreen);
        await setValue(IS_JAVASCRIPT_ENABLE, mModel.appconfiguration!.isJavascriptEnable);
        await setValue(IS_ZOOM_FUNCTIONALITY, mModel.appconfiguration!.isZoomFunctionality);
        await setValue(NAVIGATIONSTYLE, mModel.appconfiguration!.navigationStyle.validate());
        await setValue(HEADERSTYLE, mModel.appconfiguration!.headerStyle);

        if (mModel.appconfiguration!.isWalkthrough != null) {
          await setValue(IS_WALKTHROUGH, mModel.appconfiguration!.isWalkthrough);
        }

        if (mModel.appconfiguration!.isWebrtc != null) {
          await setValue(IS_WEBRTC, mModel.appconfiguration!.isWebrtc);
        }

        if (mModel.appconfiguration!.floatingButton != null) {
          await setValue(FLOATING_LOGO, mModel.appconfiguration!.floatingButton);
        }
        if (mModel.appconfiguration!.appLogo != null) {
          await setValue(APPLOGO, mModel.appconfiguration!.appLogo);
        }

        if (mModel.appconfiguration!.isFloatingButton != null) {
          await setValue(IS_FLOATING, mModel.appconfiguration!.isFloatingButton);
        } else {
          await setValue(IS_FLOATING, "false");
        }

        if (mModel.appconfiguration!.floatingButtonStyle != null) {
          await setValue(FLOATING_STYLE, mModel.appconfiguration!.floatingButtonStyle);
        }

        if (mModel.appconfiguration!.tabStyle != null) {
          await setValue(TAB_BAR_STYLE, mModel.appconfiguration!.tabStyle);
        }
        if (mModel.appconfiguration!.isPullRefresh != null) {
          await setValue(IS_PULL_TO_REFRESH, mModel.appconfiguration!.isPullRefresh);
        }

        if (mModel.appconfiguration!.isCookieEnable != null) {
          await setValue(IS_COOKIE, mModel.appconfiguration!.isCookieEnable);
        }

        if (mModel.appconfiguration!.bottomNavigation != null) {
          await setValue(BOTTOM_NAVIGATION_STYLE, mModel.appconfiguration!.bottomNavigation);
        }
        if (mModel.appconfiguration!.isSplashScreen != null) {
          await setValue(IS_SPLASH_SCREEN, mModel.appconfiguration!.isSplashScreen);
        }
        if (mModel.appconfiguration!.walkthroughStyle != null) {
          await setValue(WALK_THROUGH_STYLE, mModel.appconfiguration!.walkthroughStyle.validate());
        }
        if (mModel.appconfiguration!.isExitPopupScreen != null) {
          await setValue(IS_Exit_POP_UP, mModel.appconfiguration!.isExitPopupScreen);
        }
        if (mModel.appconfiguration!.disableHeader != null) {
          await setValue(DISABLE_HEADER, mModel.appconfiguration!.disableHeader);
        }
        if (mModel.appconfiguration!.disableFooter != null) {
          await setValue(DISABLE_FOOTER, mModel.appconfiguration!.disableFooter);
        }
      }

      // AdMob
      if (mModel.admob != null) {
        await setValue(ADD_TYPE, mModel.admob!.adsType.validate());

        await setValue(AD_MOB_BANNER_ID, mModel.admob!.admobBannerID.validate());
        await setValue(AD_MOB_INTERSTITIAL_ID, mModel.admob!.admobIntentialID.validate());
        await setValue(AD_MOB_BANNER_ID_IOS, mModel.admob!.admobBannerIDIOS.validate());
        await setValue(AD_MOB_INTERSTITIAL_ID_IOS, mModel.admob!.admobIntentialIDIOS.validate());
        await setValue(FACEBOOK_BANNER_PLACEMENT_ID, mModel.admob!.facebookBannerID.validate());
        await setValue(FACEBOOK_INTERSTITIAL_PLACEMENT_ID, mModel.admob!.facebookIntentialID.validate());
        await setValue(FACEBOOK_BANNER_PLACEMENT_ID_IOS, mModel.admob!.facebookBannerIDIOS.validate());
        await setValue(FACEBOOK_INTERSTITIAL_PLACEMENT_ID_IOS, mModel.admob!.facebookIntentialIDIOS.validate());
      }

      // Loader Style
      if (mModel.progressbar != null) {
        if (mModel.progressbar!.isProgressbar != null) {
          await setValue(IS_LOADER, mModel.progressbar!.isProgressbar);
        } else {
          await setValue(IS_LOADER, "false");
        }
        await setValue(LOADER_STYLE, mModel.progressbar!.loaderStyle.validate());
        appStore.setLoader(mModel.progressbar!.loaderStyle.validate());
      } else {
        await setValue(IS_LOADER, "true");
      }

      // Theme Style
      if (mModel.theme != null) {
        await setValue(THEME_STYLE, mModel.theme!.themeStyle.validate());
        if (getStringAsync(THEME_STYLE) == THEME_STYLE_CUSTOM) {
          await setValue(THEME_STYLE, mModel.theme!.customColor.validate());
          appStore.setPrimaryColor(hexStringToHexInt(getStringAsync(THEME_STYLE)));
        } else if (getStringAsync(THEME_STYLE) == THEME_STYLE_DEFAULT) {
          appStore.setPrimaryColor(primaryColor1);
        } else if (getStringAsync(THEME_STYLE) == THEME_STYLE_GRADIENT) {
          await setValue(GRADIENT1, mModel.theme!.gradientColor1);
          await setValue(GRADIENT2, mModel.theme!.gradientColor2);
          appStore.setPrimaryColor(hexStringToHexInt(mModel.theme!.gradientColor1!));
        } else {
          await setValue(THEME_STYLE, mModel.theme!.themeStyle);
          var theme = getStringAsync(THEME_STYLE);
          try {
            for (var i = 0; i < themeName.length; i++) {
              if (themeName[i] == theme) {
                appStore.setPrimaryColor(hexStringToHexInt(colorName[i]));
                break;
              }
            }
          } catch (e) {
            print(e);
          }
        }
      }

      // About
      if (mModel.about != null) {
        await setValue(IS_SHOW_ABOUT, mModel.about!.isShowAbout.validate());
        await setValue(WHATS_APP_NUMBER, mModel.about!.whatsAppNumber.validate());
        await setValue(INSTA_GRAM_URL, mModel.about!.instagramUrl.validate());
        await setValue(TWITTER_URL, mModel.about!.twitterUrl.validate());
        await setValue(FACEBOOK_URL, mModel.about!.facebookUrl.validate());
        await setValue(CALL_NUMBER, mModel.about!.callNumber.validate());
        await setValue(SKYPE, mModel.about!.skype.validate());
        await setValue(SNAPCHAT, mModel.about!.snapchat.validate());
        await setValue(YOUTUBE, mModel.about!.youtube.validate());
        await setValue(MESSENGER, mModel.about!.messenger.validate());
        await setValue(COPYRIGHT, mModel.about!.copyright.validate());
        await setValue(DESCRIPTION, mModel.about!.description.validate());
      }

      // One Single
      if (mModel.onesignalConfiguration != null) await setValue(ONESINGLE, mModel.onesignalConfiguration!.appId);

      if (mModel.splashConfiguration != null) {
        await setValue(SPLASH_FIRST_COLOR, mModel.splashConfiguration!.firstColor.validate());
        await setValue(SPLASH_SECOND_COLOR, mModel.splashConfiguration!.secondColor.validate());
        await setValue(SPLASH_TITLE, mModel.splashConfiguration!.title.validate());
        await setValue(SPLASH_ENABLE_TITLE, mModel.splashConfiguration!.enableTitle.validate());
        await setValue(SPLASH_ENABLE_LOGO, mModel.splashConfiguration!.enableLogo.validate());
        await setValue(SPLASH_ENABLE_BACKGROUND, mModel.splashConfiguration!.enableBackground.validate());
        await setValue(SPLASH_LOGO_URL, mModel.splashConfiguration!.splashLogoUrl.validate());
        await setValue(SPLASH_BACKGROUND_URL, mModel.splashConfiguration!.splashBackgroundUrl.validate());
        await setValue(SPLASH_TITLE_COLOR, mModel.splashConfiguration!.titleColor.validate());
      }

      // Header Icons
      if (mModel.headerIcon != null) {
        await setValue(LEFTICON, jsonEncode(mModel.headerIcon!.lefticon.validate()));
        await setValue(RIGHTICON, jsonEncode(mModel.headerIcon!.righticon.validate()));
      }

      // Menu list
      if (mModel.menuStyle != null) {
        await removeKey(MENU_STYLE);
        await removeKey(BOTTOMMENU);
        await removeKey(BOTTOMSIDEMENU);
        appStore.mBottomNavigationList.clear();
        appStore.mMenuList.clear();

        // await setValue(MENU_STYLE, jsonEncode(mModel.menuStyle));
        mModel.menuStyle.forEachIndexed((element, index) {
          if (mModel.appconfiguration!.navigationStyle == NAVIGATION_STYLE_BOTTOM_NAVIGATION_SIDE_DRAWER) {
            if (element.type == NAVIGATION_STYLE_BOTTOM_NAVIGATION) {
              if (element.status == "1") {
                appStore.addToBottomNavigationLis(element);
              }
            } else {
              if (element.status == "1") {
                appStore.addToMenuList(element);
              }
            }
          } else {
            if (element.status == "1") {
              appStore.addToBottomNavigationLis(element);
            }
          }
        });
        await setValue(BOTTOMMENU, jsonEncode(appStore.mBottomNavigationList));
        await setValue(BOTTOMSIDEMENU, jsonEncode(appStore.mMenuList));
        await setValue(MENU_STYLE, jsonEncode(appStore.mBottomNavigationList));
      } else {
        List<MenuStyleModel> mBottomNavigationList = [];
        await setValue(BOTTOMMENU, jsonEncode(mBottomNavigationList));
      }

      // Walk Through List
      if (mModel.walkthrough != null) {
        appStore.mOnBoardList.clear();
        mModel.walkthrough.forEachIndexed((element, index) {
          if (element.status == "1") {
            appStore.addToOnBoardList(element);
          }
        });
        await setValue(WALKTHROUGH, jsonEncode(appStore.mOnBoardList));
      } else {
        List<Walkthrough> mWalkList = [];
        await setValue(WALKTHROUGH, jsonEncode(mWalkList));
      }

      // FAB List
      if (mModel.floatingButton != null) {
        appStore.mFABList.clear();
        await removeKey(FLOATING_DATA);
        mModel.floatingButton.forEachIndexed((element, index) {
          if (element.status == "1") {
            appStore.addToFabList(element);
          }
        });
        await setValue(FLOATING_DATA, jsonEncode(appStore.mFABList));
      } else {
        List<FloatingButton> mFloatingList = [];
        await setValue(FLOATING_DATA, jsonEncode(mFloatingList));
      }

      // Tab List
      if (mModel.tabs != null) {
        await removeKey(TABS);
        appStore.mTabList.clear();
        mModel.tabs.forEachIndexed((element, index) {
          if (element.status == "1") {
            appStore.addToTabList(element);
          }
        });
        await setValue(TABS, jsonEncode(appStore.mTabList));
      } else {
        List<TabsResponse> mTabList = [];
        await setValue(TABS, jsonEncode(mTabList));
      }

      // User Agent
      if (mModel.userAgentResponse != null) {
        mModel.userAgentResponse.forEachIndexed((element, index) async {
          if (element.status == "1") {
            if (isIOS) {
              await setValue(USER_AGENT, element.ios!.isNotEmpty ? element.ios : "random");
            } else {
              await setValue(USER_AGENT, element.android!.isNotEmpty ? element.android : "random");
            }
          }
        });
      }

      // Exist
      if (mModel.exitPopupConfiguration != null) {
        await setValue(EXIST_ENABLE_ICON, mModel.exitPopupConfiguration!.enableImage.validate());
        await setValue(EXIST_ICON, mModel.exitPopupConfiguration!.exitImageUrl.validate());
        await setValue(EXIST_TITLE, mModel.exitPopupConfiguration!.title.validate());
        await setValue(EXIST_NEGATIVE_TEXT, mModel.exitPopupConfiguration!.negativeText.validate());
        await setValue(EXIST_POSITIVE_TEXT, mModel.exitPopupConfiguration!.positiveText.validate());
      }

      //Pages
      if (mModel.pages != null) {
        await removeKey(PAGES);
        appStore.mPageList.clear();
        mModel.pages.forEachIndexed((element, index) {
          if (element.status == "1") {
            appStore.addToPageList(element);
          }
        });
        await setValue(PAGES, jsonEncode(appStore.mPageList));
      } else {
        List<TabsResponse> mPageList = [];
        await setValue(PAGES, jsonEncode(mPageList));
      }

      if (mModel.shareContent != null) await setValue(SHARE_CONTENT, mModel.shareContent!.share);
    }

    return mModel;
  }).catchError((e) {
    log(e);
    throw e.toString();
  });
}
