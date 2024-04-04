import 'dart:convert';

import 'package:flutter/material.dart';
import '../main.dart';
import '../model/MainResponse.dart' as model1;
import '../utils/BubbleBotoomBar.dart';
import '../utils/constant.dart';
import 'package:nb_utils/nb_utils.dart';

// ignore: must_be_immutable
class BottomNavigationComponent2 extends StatefulWidget {
  static String tag = '/BottomNavigationComponent2';

  @override
  BottomNavigationComponent2State createState() => BottomNavigationComponent2State();
}

class BottomNavigationComponent2State extends State<BottomNavigationComponent2> {
  List<model1.MenuStyleModel>? mBottomMenuList;
  var currentIndex = 0;

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
    return mBottomMenuList!=null?BubbleBottomBar(
      opacity: .2,
      currentIndex: currentIndex,
      backgroundColor: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      elevation: 8,
      onTap: (index) {
        setState(() {
          appStore.currentIndex = index;
          appStore.setIndex(index);
          currentIndex = index;
        });
      },
      hasNotch: false,
      hasInk: true,
      inkColor: appStore.primaryColors,
      items: <BubbleBottomBarItem>[
        //  if(mBottomMenuList!=null)
        for (int i = 0; i < mBottomMenuList!.length; i++) tab(mBottomMenuList![i].image.validate(), mBottomMenuList![i].title.toString(), context)
      ],
    ):SizedBox();
  }
}
