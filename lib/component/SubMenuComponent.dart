import 'package:flutter/material.dart';
import '../main.dart';
import '../model/MainResponse.dart' as model1;
import '../screen/WebScreen.dart';
import '../utils/AppWidget.dart';
import 'package:nb_utils/nb_utils.dart';

class SubMenuComponent extends StatefulWidget {
  static String tag = '/TestScreen';

  final model1.MenuStyleModel? mMenuList;
  final int? i;

  const SubMenuComponent({Key? key, this.mMenuList, this.i}) : super(key: key);

  @override
  SubMenuComponentState createState() => SubMenuComponentState();
}

class SubMenuComponentState extends State<SubMenuComponent> {
  List<model1.MenuStyleModel> subList = [];
  bool? isParentSelect = false;
  bool? isChilderenSelect = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    //
    if (widget.mMenuList!.children != null) {
      subList.addAll(widget.mMenuList!.children!);
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Widget mTestWidget(List<model1.MenuStyleModel>? mMenuList) {
    return ListView.builder(
      itemCount: mMenuList!.length,
      shrinkWrap: true,
      scrollDirection: Axis.vertical,
      padding: EdgeInsets.only(left: 16),
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Theme(
          data: ThemeData(
            dividerColor: Colors.transparent,
          ),
          child: ExpansionTile(dense: true,
            onExpansionChanged: (value) {
              if (mMenuList[index].children!.isEmpty) {
                finish(context);
                WebScreen(mHeading: mMenuList[index].title, mInitialUrl: mMenuList[index].url).launch(context);
              }
              isChilderenSelect = value;
            },
            shape: RoundedRectangleBorder(
              side: BorderSide.none,
            ),
            collapsedShape: RoundedRectangleBorder(
              side: BorderSide.none,
            ),
            title: Transform.translate(
              offset: Offset(-17, 0),
              child: Text(mMenuList[index].title!.trim(), style: primaryTextStyle()),
            ),
            trailing: mMenuList[index].children.validate().isEmpty
                ? SizedBox()
                : Icon(isChilderenSelect == false ? Icons.keyboard_arrow_right : Icons.keyboard_arrow_down_rounded, color: Theme.of(context).iconTheme.color!.withOpacity(0.5)),
            tilePadding: EdgeInsets.all(0),
            childrenPadding: EdgeInsets.all(0),
            leading: appStore.isDarkModeOn == true
                ? cachedImage(mMenuList[index].image, width: 22, height: 22, color:Colors.white).paddingRight(16)
                : cachedImage(mMenuList[index].image, width: 22, height: 22).paddingRight(16),
            children: [
              ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.only(left: 16),
                scrollDirection: Axis.vertical,
                itemCount: mMenuList[index].children!.length,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, i) {
                  model1.MenuStyleModel data = mMenuList[index].children![i];
                  return SettingItemWidget(
                    paddingAfterLeading: 14,
                    title: data.title!.validate().trim(),
                    padding: EdgeInsets.only(top: 6, bottom: 6),
                    titleTextStyle: primaryTextStyle(),
                    leading: appStore.isDarkModeOn == true ? cachedImage(data.image, width: 22, height: 22, color: Theme.of(context).iconTheme.color) : cachedImage(data.image, width: 22, height: 22),
                    onTap: () {
                      if (data.children!.isNotEmpty || data.children == null) {
                        SubMenuComponent(mMenuList: data.children![index]);
                      } else {
                        finish(context);
                        WebScreen(mHeading: data.title, mInitialUrl: data.url).launch(context);
                      }
                    },
                  );
                },
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        expandedAlignment: Alignment.topLeft,
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        title: Transform.translate(
          offset: Offset(-17, 0),
          child: Text(widget.mMenuList!.title!.trim(), style: primaryTextStyle()),
        ),
        onExpansionChanged: (value) {
          setState(() {
            if (widget.mMenuList!.children!.isEmpty) {
              finish(context);
              WebScreen(mHeading: widget.mMenuList!.title, mInitialUrl: widget.mMenuList!.url).launch(context);
            }
            isParentSelect = value;
          });
        },
        trailing: widget.mMenuList!.children!.isEmpty
            ? SizedBox()
            : Icon(isParentSelect == false ? Icons.keyboard_arrow_right : Icons.keyboard_arrow_down_rounded, color: Theme.of(context).iconTheme.color!.withOpacity(0.5)),
        tilePadding: EdgeInsets.all(0),
        childrenPadding: EdgeInsets.all(0),
        leading: appStore.isDarkModeOn == true
            ? cachedImage(widget.mMenuList!.image, width: 22, height: 22, fit: BoxFit.fitWidth, color: Theme.of(context).iconTheme.color!.withOpacity(0.5)).paddingRight(16)
            : cachedImage(widget.mMenuList!.image, width: 22, height: 22, fit: BoxFit.fitWidth).paddingRight(16),
        children: <Widget>[
          mTestWidget(widget.mMenuList!.children),
        ],
      ),
    );
  }
}
