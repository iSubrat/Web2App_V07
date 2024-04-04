import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../screen/DashboardScreen.dart';
import '../utils/colors.dart';
import '../utils/constant.dart';
import '../utils/loader.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:store_redirect/store_redirect.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../utils/common.dart';

// ignore: must_be_immutable
class WebScreen extends StatefulWidget {
  static String tag = '/WebScreen';

  String? mInitialUrl;
  String? mHeading;
  bool? isDownload;
  bool? isQrScan;

  WebScreen({this.mInitialUrl, this.mHeading, this.isDownload = false, this.isQrScan = false});

  @override
  WebScreenState createState() => WebScreenState();
}

class WebScreenState extends State<WebScreen> {
  bool isWasConnectionLoss = false;
  bool mIsPermissionGrant = false;

  PullToRefreshController? pullToRefreshController;

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

  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    log(widget.mInitialUrl);
    if (widget.isDownload == true) {
      Share.share(widget.mInitialUrl!);
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
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        setState(() {
          isWasConnectionLoss = true;
        });
      } else {
        setState(() {
          isWasConnectionLoss = false;
        });
      }
    });
    setState(() {});
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
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Future<bool> _exitApp() async {
    if (await webViewController!.canGoBack()) {
      webViewController!.goBack();
      return false;
    } else {
      Navigator.pop(context);
      if (widget.isQrScan == true) DashBoardScreen().launch(context);
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _exitApp,
      child: Scaffold(
        backgroundColor: context.cardColor,
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
          leading: IconButton(
            icon: Icon(Icons.chevron_left_sharp, color: white, size: 18),
            onPressed: () {
              _exitApp();
            },
          ),
          title: Text(widget.mHeading!, style: boldTextStyle(color: white)),
        ),
        bottomNavigationBar: getStringAsync(NAVIGATIONSTYLE) == NAVIGATION_STYLE_BOTTOM_NAVIGATION ? SizedBox() : showBannerAds(),
        body: Stack(
          children: [
            InAppWebView(
              key: webViewKey,
              initialUrlRequest: URLRequest(url: WebUri.uri(Uri.parse(widget.mInitialUrl == null ? 'https://www.google.com' : widget.mInitialUrl!))),
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
                if (getStringAsync(IS_LOADER) == "true") appStore.setLoading(false);
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
                pullToRefreshController!.endRefreshing();
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
                log("URL" + url.toString());

                if (Platform.isAndroid && url.contains("intent")) {
                  if (url.contains("maps")) {
                    var mNewURL = url.replaceAll("intent://", "https://");
                    if (await canLaunchUrl(Uri.parse(mNewURL))) {
                      await launchUrl(Uri.parse(mNewURL));
                      return NavigationActionPolicy.CANCEL;
                    }
                  } else {
                    String id = url.substring(url.indexOf('id%3D') + 5, url.indexOf('#Intent'));
                    await StoreRedirect.redirect(androidAppId: id);
                    return NavigationActionPolicy.CANCEL;
                  }
                } else if (url.contains("linkedin.com") ||
                    url.contains("market://") ||
                    url.contains("whatsapp://") ||
                    url.contains("truecaller://") ||
                    url.contains("facebook.com") ||
                    url.contains("twitter.com") ||
                    url.contains("youtube.com") ||
                    url.contains("pinterest.com") ||
                    url.contains("snapchat.com") ||
                    url.contains("instagram.com") ||
                    url.contains("play.google.com") ||
                    url.contains("mailto:") ||
                    url.contains("tel:") ||
                    url.contains("share=telegram") ||
                    url.contains("messenger.com")) {
                  url = Uri.encodeFull(url);
                  try {
                    if (widget.isQrScan == true) {
                      finish(context);
                      finish(context);
                    }
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
              },
            ).visible(isWasConnectionLoss == false),
            Container(color: Colors.white, height: context.height(), width: context.width(), child: Loaders(name: appStore.loaderValues).center()).visible(appStore.isLoading)
          ],
        ),
      ),
    );
  }
}
