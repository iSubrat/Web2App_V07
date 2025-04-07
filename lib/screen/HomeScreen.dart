import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:facebook_audience_network/facebook_audience_network.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../app_localizations.dart';
import '../component/AppBarComponent.dart';
import '../component/FloatingComponent.dart';
import '../component/SideMenuComponent.dart';
import '../main.dart';
import '../model/MainResponse.dart';
import '../screen/DashboardScreen.dart';
import '../utils/AppWidget.dart';
import '../utils/common.dart';
import '../utils/constant.dart';
import '../utils/loader.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:store_redirect/store_redirect.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'QRScannerScreen.dart';

class HomeScreen extends StatefulWidget {
  static String tag = '/HomeScreen';

  final String? mUrl, title;

  HomeScreen({this.mUrl, this.title});

  @override
  _HomeScreenState createState() => new _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  InAppWebViewController? webViewController;
  ReceivePort port = ReceivePort();
  PullToRefreshController? pullToRefreshController;

  List<TabsResponse> mTabList = [];
  List<MenuStyleModel> mBottomMenuList = [];

  String? mInitialUrl;

  bool isWasConnectionLoss = false;
  bool mIsPermissionGrant = false;

  InAppWebViewSettings options = InAppWebViewSettings(
    useShouldOverrideUrlLoading: true,
    userAgent: getStringAsync(USER_AGENT),
    mediaPlaybackRequiresUserGesture: false,
    allowFileAccessFromFileURLs: true,
    useOnDownloadStart: true,
    javaScriptEnabled: getStringAsync(IS_JAVASCRIPT_ENABLE) == "true" ? true : false,
    javaScriptCanOpenWindowsAutomatically: true,
    supportZoom: getStringAsync(IS_ZOOM_FUNCTIONALITY) == "true" ? true : false,
    incognito: getStringAsync(IS_COOKIE) == "true" ? true : false,
    useHybridComposition: true,
    allowsInlineMediaPlayback: true,transparentBackground: true
  );

  void _getInstanceId() async {
    await Firebase.initializeApp();
    FirebaseInAppMessaging.instance.triggerEvent("");
    FirebaseMessaging.instance.sendMessage();
    FirebaseMessaging.instance.getInitialMessage();
  }

  @override
  void initState() {
    super.initState();
    FacebookAudienceNetwork.init(testingId: FACEBOOK_KEY, iOSAdvertiserTrackingEnabled: true);
    Iterable mTabs = jsonDecode(getStringAsync(TABS));
    mTabList = mTabs.map((model) => TabsResponse.fromJson(model)).toList();
    _getInstanceId();
    if (getStringAsync(IS_WEBRTC) == "true") {
      checkWebRTCPermission();
    }
    pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(color: appStore.primaryColors, enabled: getStringAsync(IS_PULL_TO_REFRESH) == "true" ? true : false),
      onRefresh: () async {
        if (Platform.isAndroid) {
          webViewController?.reload();
        } else if (Platform.isIOS) {
          webViewController?.loadUrl(urlRequest: URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );
    init();
    loadInterstitialAds();
  }

  Future<bool> checkPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (status != PermissionStatus.granted) {
        final result = await Permission.storage.request();
        if (result == PermissionStatus.granted) {
          mIsPermissionGrant = true;
          setState(() {});
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

  @override
  void dispose() {
    init();
    super.dispose();
  }

  Future<void> init() async {
    String? referralCode = getReferralCodeFromNative();
    if (referralCode!.isNotEmpty) {
      mInitialUrl = referralCode;
    }

    if (getStringAsync(NAVIGATIONSTYLE) == NAVIGATION_STYLE_BOTTOM_NAVIGATION_SIDE_DRAWER) {
      Iterable mBottom = jsonDecode(getStringAsync(MENU_STYLE));
      mBottomMenuList = mBottom.map((model) => MenuStyleModel.fromJson(model)).toList();
    } else {
      Iterable mBottom = jsonDecode(getStringAsync(BOTTOMMENU));
      mBottomMenuList = mBottom.map((model) => MenuStyleModel.fromJson(model)).toList();
    }
    if (getStringAsync(NAVIGATIONSTYLE) == NAVIGATION_STYLE_BOTTOM_NAVIGATION || getStringAsync(NAVIGATIONSTYLE) == NAVIGATION_STYLE_BOTTOM_NAVIGATION_SIDE_DRAWER) {
      if (mBottomMenuList.isNotEmpty) {
        mInitialUrl = widget.mUrl;
      } else {
        mInitialUrl = getStringAsync(URL);
      }
    } else if (getStringAsync(NAVIGATIONSTYLE) == NAVIGATION_STYLE_TAB_BAR || getStringAsync(NAVIGATIONSTYLE) == NAVIGATION_STYLE_SIDE_DRAWER_TABS) {
      log(widget.mUrl);
      if (mTabList.isNotEmpty) {
        mInitialUrl = widget.mUrl;
        log(mInitialUrl);
      } else {
        mInitialUrl = getStringAsync(URL);
      }
    } else {
      mInitialUrl = getStringAsync(URL);
    }

    if (webViewController != null) {
      await webViewController!.loadUrl(urlRequest: URLRequest(url:WebUri.uri( Uri.parse(mInitialUrl!))));
    } else {
      log("sorry");
    }
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {
      init();
    });
  }

  @override
  Widget build(BuildContext context) {
    var appLocalization = AppLocalizations.of(context);
    Future<bool> _exitApp() async {
      if (await webViewController!.canGoBack()) {
        webViewController!.goBack();
        return false;
      } else {
        showInterstitialAds();

        if (getStringAsync(IS_Exit_POP_UP) == "true") {
          return mConfirmationDialog(() {
            Navigator.of(context).pop(false);
          }, context, appLocalization);
        } else {
          exit(0);
        }
      }
    }

    Widget mLoadWeb({String? mURL}) {
      return Stack(
        children: [
          InAppWebView(
              initialUrlRequest: URLRequest(url:WebUri.uri(  Uri.parse(mURL.isEmptyOrNull ? mInitialUrl.validate() : mURL!))),
              initialSettings: options,
              pullToRefreshController: pullToRefreshController,
              onWebViewCreated: (controller) {
                webViewController = controller;
              },
              onLoadStart: (controller, url) {
                log("onLoadStart");
                if (getStringAsync(IS_LOADER) == "true") appStore.setLoading(true);
                setState(() {});
              },
              onProgressChanged: (controller, progress) {
                if (progress == 100) {
                  pullToRefreshController!.endRefreshing();
                  if (getStringAsync(IS_LOADER) == "true") appStore.setLoading(false);
                  setState(() {});
                }
              },
              onLoadStop: (controller, url) async {
                log("onLoadStop");
                pullToRefreshController!.endRefreshing();
                if (getStringAsync(IS_LOADER) == "true") appStore.setLoading(false);
                //webViewController!.evaluateJavascript(source: 'document.getElementsByClassName("navbar-main")[0].style.display="none";');
                if (getStringAsync(DISABLE_HEADER) == "true") {
                  webViewController!
                      .evaluateJavascript(source: "javascript:(function() { " + "var head = document.getElementsByTagName('header')[0];" + "head.parentNode.removeChild(head);" + "})()")
                      .then((value) => debugPrint('Page finished loading Javascript'))
                      .catchError((onError) => debugPrint('$onError'));
                }
                if (getStringAsync(DISABLE_FOOTER) == "true") {
                  webViewController!
                      .evaluateJavascript(source: "javascript:(function() { " + "var footer = document.getElementsByTagName('footer')[0];" + "footer.parentNode.removeChild(footer);" + "})()")
                      .then((value) => debugPrint('Page finished loading Javascript'))
                      .catchError((onError) => debugPrint('$onError'));
                }
                setState(() {});
              },
              onReceivedError:(controller, request, error) {
                log("onLoadError");
                if (getStringAsync(IS_LOADER) == "true") appStore.setLoading(false);
                setState(() {});
                pullToRefreshController!.endRefreshing();
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                var uri = navigationAction.request.url;
                var url = navigationAction.request.url.toString();
                log("URL->" + url.toString());

                if (Platform.isAndroid && url.contains("intent")) {
                  if (url.contains("maps")) {
                    var mNewURL = url.replaceAll("intent://", "https://");
                    if (await canLaunchUrl(Uri.parse(mNewURL))) {
                      await launchUrl(Uri.parse(mNewURL), mode: LaunchMode.externalApplication);
                      return NavigationActionPolicy.CANCEL;
                    }
                  } else {
                    String id = url.substring(url.indexOf('id%3D') + 5, url.indexOf('#Intent'));
                    await StoreRedirect.redirect(androidAppId: id);
                    return NavigationActionPolicy.CANCEL;
                  }
                } else if (url.contains("linkedin.com") ||
                    url.contains("market://") ||
                    url.contains("upi://") ||
                    url.contains("pay?") ||
                    url.contains("whatsapp://") ||
                    url.contains("truecaller://") ||
                    url.contains("pinterest.com") ||
                    url.contains("snapchat.com") ||
                    url.contains("youtube.com") ||
                    url.contains("instagram.com") ||
                    url.contains("play.google.com") ||
                    url.contains("mailto:") ||
                    url.contains("tel:") ||
                    url.contains("share=telegram") ||
                    url.contains("messenger.com")) {
                  if (url.contains("https://api.whatsapp.com/send?phone=+")) {
                    url = url.replaceAll("https://api.whatsapp.com/send?phone=+", "https://api.whatsapp.com/send?phone=");
                  } else if (url.contains("whatsapp://send/?phone=%20")) {
                    url = url.replaceAll("whatsapp://send/?phone=%20", "whatsapp://send/?phone=");
                  }
                  if (!url.contains("whatsapp://")) {
                    url = Uri.encodeFull(url);
                  }
                  try {
                    if (await canLaunchUrl(Uri.parse(url))) {
                      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    } else {
                      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    }
                    return NavigationActionPolicy.CANCEL;
                  } catch (e) {
                    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    return NavigationActionPolicy.CANCEL;
                  }
                } else if (!["http", "https", "chrome", "data", "javascript", "about"].contains(uri!.scheme)) {
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

                    return NavigationActionPolicy.CANCEL;
                  }
                }
                return NavigationActionPolicy.ALLOW;
              },
              onDownloadStartRequest: (controller, downloadStartRequest) {
                launchUrl(Uri.parse(downloadStartRequest.url.toString()), mode: LaunchMode.externalApplication);
              },
              onGeolocationPermissionsShowPrompt: (InAppWebViewController controller, String origin) async {
                await Permission.location.request();
                return Future.value(GeolocationPermissionShowPromptResponse(origin: origin, allow: true, retain: true));
              },
              androidOnPermissionRequest: (InAppWebViewController controller, String origin, List<String> resources) async {
                if (resources.length >= 1) {
                } else {
                  resources.forEach((element) async {
                    if (element.contains("AUDIO_CAPTURE")) {
                      await Permission.microphone.request();
                    }
                    if (element.contains("VIDEO_CAPTURE")) {
                      await Permission.camera.request();
                    }
                  });
                }
                return PermissionRequestResponse(resources: resources, action: PermissionRequestResponseAction.GRANT);
              }).visible(isWasConnectionLoss == false),
          Container(color: Colors.white, height: context.height(), width: context.width(), child: Loaders(name: appStore.loaderValues).center()).visible(appStore.isLoading)
        ],
      );
    }

    Widget mBody() {
      return Container(
        color: getStringAsync(NAVIGATIONSTYLE) == NAVIGATION_STYLE_FULL_SCREEN ? whiteColor : appStore.primaryColors,
        child: SafeArea(
          child: Scaffold(
            backgroundColor: context.cardColor,
            drawerEdgeDragWidth: 0,
            appBar: getStringAsync(NAVIGATIONSTYLE) != NAVIGATION_STYLE_FULL_SCREEN
                ? PreferredSize(
                    child: AppBarComponent(
                      onTap: (value) {
                        if (value == RIGHT_ICON_RELOAD) {
                          webViewController!.reload();
                        }
                        if (RIGHT_ICON_SHARE == value) {
                          Share.share(getStringAsync(SHARE_CONTENT));
                        }
                        if (RIGHT_ICON_CLOSE == value || LEFT_ICON_CLOSE == value) {
                          if (getStringAsync(IS_Exit_POP_UP) == "true") {
                            mConfirmationDialog(() {
                              Navigator.of(context).pop(false);
                            }, context, appLocalization);
                          }
                        }
                        if (RIGHT_ICON_SCAN == value) {
                          QRScannerScreen().launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
                        }
                        if (LEFT_ICON_BACK_1 == value) {
                          _exitApp();
                        }
                        if (LEFT_ICON_BACK_2 == value) {
                          _exitApp();
                        }
                        if (LEFT_ICON_HOME == value) {
                          DashBoardScreen().launch(context);
                        }
                      },
                    ),
                    preferredSize: Size.fromHeight(
                        getStringAsync(NAVIGATIONSTYLE) == NAVIGATION_STYLE_TAB_BAR || getStringAsync(NAVIGATIONSTYLE) == NAVIGATION_STYLE_SIDE_DRAWER_TABS && appStore.mTabList.length != 0
                            ? 100.0
                            : 60.0),
                  )
                : PreferredSize(
                    child: SizedBox(),
                    preferredSize: Size.fromHeight(0.0),
                  ),
            floatingActionButton: getStringAsync(IS_FLOATING) == "true" ? FloatingComponent() : SizedBox(),
            drawer: Drawer(
              child: SideMenuComponent(onTap: () {
                mInitialUrl = getStringAsync(URL).isNotEmpty ? getStringAsync(URL) : "https://www.google.com";
                webViewController!.reload();
              }),
            ).visible(getStringAsync(NAVIGATIONSTYLE) == NAVIGATION_STYLE_SIDE_DRAWER ||
                getStringAsync(NAVIGATIONSTYLE) == NAVIGATION_STYLE_BOTTOM_NAVIGATION_SIDE_DRAWER ||
                getStringAsync(NAVIGATIONSTYLE) == NAVIGATION_STYLE_SIDE_DRAWER_TABS),
            body: getStringAsync(NAVIGATIONSTYLE) == NAVIGATION_STYLE_TAB_BAR || getStringAsync(NAVIGATIONSTYLE) == NAVIGATION_STYLE_SIDE_DRAWER_TABS && appStore.mTabList.length != 0
                ? TabBarView(
                    physics: NeverScrollableScrollPhysics(),
                    children: [
                      for (int i = 0; i < mTabList.length; i++) mLoadWeb(mURL: mTabList[i].url),
                    ],
                  )
                : mLoadWeb(mURL: mInitialUrl),
            bottomNavigationBar: getStringAsync(NAVIGATIONSTYLE) == NAVIGATION_STYLE_BOTTOM_NAVIGATION || getStringAsync(NAVIGATIONSTYLE) == NAVIGATION_STYLE_BOTTOM_NAVIGATION_SIDE_DRAWER
                ? SizedBox()
                : showBannerAds(),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: _exitApp,
      child: getStringAsync(NAVIGATIONSTYLE) == NAVIGATION_STYLE_TAB_BAR || getStringAsync(NAVIGATIONSTYLE) == NAVIGATION_STYLE_SIDE_DRAWER_TABS
          ? DefaultTabController(
              length: appStore.mTabList.length,
              child: mBody(),
            )
          : mBody(),
    );
  }
}
