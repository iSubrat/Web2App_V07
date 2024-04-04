import 'dart:convert';

import 'package:flutter/material.dart';
import '../main.dart';
import '../model/MainResponse.dart' as model1;
import '../utils/AppWidget.dart';
import '../utils/constant.dart';
import 'package:nb_utils/nb_utils.dart';

// ignore: must_be_immutable
class BottomNavigationComponent1 extends StatefulWidget {
  static String tag = '/BottomNavigationComponent1';

  @override
  BottomNavigationComponent1State createState() => BottomNavigationComponent1State();
}

class BottomNavigationComponent1State extends State<BottomNavigationComponent1> {
  List<model1.MenuStyleModel>? mBottomMenuList;

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    //
    if (getStringAsync(NAVIGATIONSTYLE) == NAVIGATION_STYLE_BOTTOM_NAVIGATION_SIDE_DRAWER) {
      Iterable mBottom = jsonDecode(getStringAsync(MENU_STYLE));
      mBottomMenuList = mBottom.map((model) => model1.MenuStyleModel.fromJson(model)).toList();
    } else {
      Iterable mBottom = jsonDecode(getStringAsync(BOTTOMMENU));
      mBottomMenuList = mBottom.map((model) => model1.MenuStyleModel.fromJson(model)).toList();
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return mBottomMenuList != null
        ? BottomNavigationBar(
            backgroundColor: context.cardColor,
            type: BottomNavigationBarType.shifting,
            showUnselectedLabels: true,
            showSelectedLabels: true,
            currentIndex: appStore.currentIndex,
            unselectedItemColor: textSecondaryColorGlobal,
            unselectedLabelStyle: secondaryTextStyle(),
            selectedLabelStyle: secondaryTextStyle(color: textPrimaryColorGlobal),
            selectedItemColor: appStore.primaryColors,
            items: [
              for (int i = 0; i < mBottomMenuList!.length; i++)
                BottomNavigationBarItem(
                  icon: cachedImage(mBottomMenuList![i].image, width: 20, height: 20, color: textSecondaryColor),
                  activeIcon: cachedImage(mBottomMenuList![i].image, width: 20, height: 20, color: appStore.primaryColors),
                  label: mBottomMenuList![i].title.toString(),
                  backgroundColor:context.scaffoldBackgroundColor
                )
            ],
            onTap: (index) {
              setState(() {
                appStore.currentIndex = index;
                appStore.setIndex(index);
              });
            })
        : SizedBox();
  }
}
