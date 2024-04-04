import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../AppTheme.dart';
import '../app_localizations.dart';
import '../model/LanguageModel.dart';
import '../screen/DataScreen.dart';
import '../utils/common.dart';
import '../utils/constant.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'component/NoInternetConnection.dart';
import 'store/AppStore.dart';

AppStore appStore = AppStore();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = HttpOverridesSkipCertificate();
  await initialize();
  appStore.setDarkMode(aIsDarkMode: getBoolAsync(isDarkModeOnPref));
  appStore.setLanguage(getStringAsync(APP_LANGUAGE, defaultValue: 'en'));

  if (isMobile) {
    MobileAds.instance.initialize();
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.Debug.setAlertLevel(OSLogLevel.none);
    OneSignal.consentRequired(false);
    OneSignal.initialize(getStringAsync(ONESINGLE, defaultValue: mOneSignalID));
    OneSignal.Notifications.requestPermission(true);
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      print('NOTIFICATION WILL DISPLAY LISTENER CALLED WITH: ${event.notification.jsonRepresentation()}');
      event.preventDefault();
      event.notification.display();
    });
  }
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp();

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    setStatusBarColor(appStore.primaryColors, statusBarBrightness: Brightness.light);
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((e) async {
      appStore.setConnectionState(e);
      if (e == ConnectivityResult.none) {
        log('not connected');
        push(NoInternetConnection());
      } else {
        pop();
        log('connected');
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _connectivitySubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (context) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: appStore.isNetworkAvailable ? DataScreen() : NoInternetConnection(),
        supportedLocales: Language.languagesLocale(),
        navigatorKey: navigatorKey,
        localizationsDelegates: [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
        localeResolutionCallback: (locale, supportedLocales) => locale,
        locale: Locale(getStringAsync(APP_LANGUAGE, defaultValue: 'en')),
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: appStore.isDarkModeOn! ? ThemeMode.dark : ThemeMode.light,
        scrollBehavior: SBehavior(),
      );
    });
  }
}
