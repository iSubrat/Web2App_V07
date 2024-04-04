import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mightyweb/screen/DashboardScreen.dart';
import '../app_localizations.dart';
import '../component/SubMenuComponent.dart';
import '../main.dart';
import '../model/MainResponse.dart' as model1;
import '../model/MainResponse.dart';
import '../screen/AboutUsScreen.dart';
import '../screen/ChooseDemo.dart';
import '../screen/HomeScreen.dart';
import '../screen/SetUpScreen.dart';
import '../utils/AppWidget.dart';
import '../utils/constant.dart';
import 'package:nb_utils/nb_utils.dart';
import '../screen/WebScreen.dart';

class SideMenuComponent extends StatefulWidget {
  final Function? onTap;

  SideMenuComponent({this.onTap});

  @override
  SideMenuComponentState createState() => SideMenuComponentState();
}

class SideMenuComponentState extends State<SideMenuComponent> {
  List<model1.MenuStyleModel> mMenuList = [];
  List<TabsResponse>? mPagesList;

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    //
    if (getStringAsync(NAVIGATIONSTYLE) == NAVIGATION_STYLE_BOTTOM_NAVIGATION_SIDE_DRAWER) {
      Iterable mBottom = jsonDecode(getStringAsync(BOTTOMSIDEMENU));
      mMenuList = mBottom.map((model) => model1.MenuStyleModel.fromJson(model)).toList();
    } else {
      Iterable mBottom = jsonDecode(getStringAsync(BOTTOMMENU));
      mMenuList = mBottom.map((model) => model1.MenuStyleModel.fromJson(model)).toList();
    }

    Iterable mPages = jsonDecode(getStringAsync(PAGES));
    mPagesList = mPages.map((model) => TabsResponse.fromJson(model)).toList();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Widget mDrawerOption(String value, var icon, {Function? onTap}) {
    return SettingItemWidget(
      title: value,
      paddingAfterLeading: 14,
      padding: EdgeInsets.only(top: 8, bottom: 8),
      trailing: Icon(Icons.chevron_right, color: context.iconColor.withOpacity(0.5)),
      titleTextStyle: primaryTextStyle(),
      leading: Icon(icon),
      onTap: () {
        onTap!.call();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var appLocalization = AppLocalizations.of(context)!;
    return Observer(builder: (context) {
      return Container(
        color: context.scaffoldBackgroundColor,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              50.height,
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  cachedImage(getStringAsync(APPLOGO), height: 55, width: 55, fit: BoxFit.cover).cornerRadiusWithClipRRect(10),
                  10.width,
                  Text(getStringAsync(APPNAME), style: boldTextStyle(size: 18)).expand(),
                ],
              ),
              26.height,
              mDrawerOption(appLocalization.translate('lbl_home')!, Icons.home_filled, onTap: () {
                if (getStringAsync(NAVIGATIONSTYLE) == NAVIGATION_STYLE_BOTTOM_NAVIGATION_SIDE_DRAWER) {
                  DashBoardScreen().launch(context, isNewTask: true);
                } else
                  HomeScreen().launch(context, isNewTask: true);
              }).visible(EnableHome == true),
              Divider().visible(EnableDemo == true),
              mDrawerOption(appLocalization.translate('lbl_try_demo')!, Icons.settings, onTap: () {
                Navigator.pop(context);
                SetUpScreen().launch(context);
              }).visible(EnableDemo == true),
              Divider().visible(EnableDemo == true),
              mDrawerOption(appLocalization.translate('lbl_example')!, Icons.apps, onTap: () {
                ChooseDemo().launch(context, isNewTask: true);
              }).visible(EnableDemo == true),
              Divider().visible(EnableDemo == true),
              ListView.builder(
                itemCount: mMenuList.length,
                shrinkWrap: true,
                padding: EdgeInsets.all(0),
                scrollDirection: Axis.vertical,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, i) {
                  return SubMenuComponent(mMenuList: mMenuList[i], i: i);
                },
              ),
              Divider(thickness: 4).visible(mMenuList.isNotEmpty),
              ListView.separated(
                itemCount: mPagesList!.length,
                shrinkWrap: true,
                padding: EdgeInsets.all(0),
                scrollDirection: Axis.vertical,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, i) {
                  return SettingItemWidget(
                    title: mPagesList![i].title!.validate().trim(),
                    padding: EdgeInsets.only(top: 8, bottom: 8),
                    paddingAfterLeading: 14,
                    titleTextStyle: primaryTextStyle(),
                    trailing: Icon(Icons.keyboard_arrow_right, color: context.iconColor.withOpacity(0.5)),
                    leading:
                        appStore.isDarkModeOn == true ? cachedImage(mPagesList![i].image, width: 22, height: 22, color: context.iconColor) : cachedImage(mPagesList![i].image, width: 22, height: 22),
                    onTap: () {
                      finish(context);
                      WebScreen(mHeading: mPagesList![i].title, mInitialUrl: mPagesList![i].url).launch(context);
                    },
                  );
                },
                separatorBuilder: (BuildContext context, int index) {
                  return Divider();
                },
              ),
              Divider(
                thickness: 4,
              ).visible(mPagesList!.isNotEmpty),
              mDrawerOption(appLocalization.translate('lbl_about_us')!, Icons.info, onTap: () {
                finish(context);
                AboutUsScreen().launch(context);
              }).visible(getStringAsync(IS_SHOW_ABOUT) == "true"),
              Divider(),
              SettingItemWidget(
                title: appStore.isDarkModeOn! ? appLocalization.translate('lbl_light_mode')! : appLocalization.translate('lbl_dark_mode')!,
                padding: EdgeInsets.only(top: 6, bottom: 6),
                paddingAfterLeading: 14,
                trailing: Switch(
                  value: appStore.isDarkModeOn!,
                  onChanged: (s) {
                    appStore.setDarkMode(aIsDarkMode: s);
                    setState(() {});
                  },
                ).withHeight(24),
                titleTextStyle: primaryTextStyle(),
                leading: Icon(Icons.brightness_4_rounded),
              ).visible(EnableMode == true),
            ],
          ).paddingAll(16),
        ),
      );
    });
  }
}
