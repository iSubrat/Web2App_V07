import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../component/BottomNavigationComponent1.dart';
import '../component/BottomNavigationComponent2.dart';
import '../component/BottomNavigationComponent3.dart';
import '../main.dart';
import '../model/MainResponse.dart';
import '../utils/constant.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../utils/common.dart';
import 'HomeScreen.dart';
import 'WebScreen.dart';

class DashBoardScreen extends StatefulWidget {
  static String tag = '/DashBoardScreen';

  final String? url;

  DashBoardScreen({this.url});

  @override
  DashBoardScreenState createState() => DashBoardScreenState();
}

class DashBoardScreenState extends State<DashBoardScreen> {
  List<MenuStyleModel> mBottomMenuList=[];
  List<Widget> widgets = [];

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    setStatusBarColor(appStore.primaryColors, statusBarBrightness: Brightness.light);

    if (isMobile) {
      OneSignal.Notifications.addClickListener((event) {
        print("Notification URL"+event.notification.launchUrl.validate());
        if (!event.notification.launchUrl.isEmptyOrNull) {
          WebScreen(mInitialUrl: event.notification.launchUrl.validate(),mHeading: "",).launch(context);
        }
      });
    }

    if (getStringAsync(NAVIGATIONSTYLE) == NAVIGATION_STYLE_BOTTOM_NAVIGATION_SIDE_DRAWER) {
      Iterable mBottom = jsonDecode(getStringAsync(MENU_STYLE));
      mBottomMenuList = mBottom.map((model) => MenuStyleModel.fromJson(model)).toList();

      if (mBottomMenuList.isNotEmpty) {
        for (int i = 0; i < mBottomMenuList.length; i++) {
          widgets.add(HomeScreen(mUrl: mBottomMenuList[i].url));
        }
      } else {
        widgets.add(HomeScreen());
      }
    } else {
      Iterable mBottom = jsonDecode(getStringAsync(BOTTOMMENU));
      mBottomMenuList = mBottom.map((model) => MenuStyleModel.fromJson(model)).toList();
      if (getStringAsync(NAVIGATIONSTYLE) == NAVIGATION_STYLE_BOTTOM_NAVIGATION && mBottomMenuList.isNotEmpty) {
        for (int i = 0; i < appStore.mBottomNavigationList.length; i++) {
          widgets.add(HomeScreen(mUrl: mBottomMenuList[i].url));
        }
      } else {
        widgets.add(HomeScreen());
      }
    }

    log(appStore.currentIndex);
    setState(() {});
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget mBottomStyle() {
    if (getStringAsync(NAVIGATIONSTYLE) == NAVIGATION_STYLE_BOTTOM_NAVIGATION_SIDE_DRAWER) {
      if (getStringAsync(BOTTOM_NAVIGATION_STYLE) == BOTTOM_NAVIGATION_1)
        return BottomNavigationComponent3();
      else if (getStringAsync(BOTTOM_NAVIGATION_STYLE) == BOTTOM_NAVIGATION2)
        return BottomNavigationComponent2();
      else
        return BottomNavigationComponent1();
    } else {
      if (getStringAsync(BOTTOM_NAVIGATION_STYLE) == BOTTOM_NAVIGATION_1)
        return BottomNavigationComponent3();
      else if (getStringAsync(BOTTOM_NAVIGATION_STYLE) == BOTTOM_NAVIGATION2)
        return BottomNavigationComponent2();
      else
        return BottomNavigationComponent1();
    }
  }

  @override
  Widget build(BuildContext context) {
    return getStringAsync(NAVIGATIONSTYLE) == NAVIGATION_STYLE_BOTTOM_NAVIGATION_SIDE_DRAWER ||
            getStringAsync(NAVIGATIONSTYLE) == NAVIGATION_STYLE_BOTTOM_NAVIGATION && mBottomMenuList.isNotEmpty
        ? Scaffold(
            backgroundColor: context.scaffoldBackgroundColor,
            bottomNavigationBar: getStringAsync(ADD_TYPE) != NONE
                ? Container(
                    height: 118,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [showBannerAds(), Align(alignment: Alignment.bottomCenter, child: mBottomStyle())],
                    ),
                  )
                : mBottomStyle(),
            body: Observer(
              builder: (_) => widgets[appStore.currentIndex],
            ),
          )
        : HomeScreen();
  }
}
