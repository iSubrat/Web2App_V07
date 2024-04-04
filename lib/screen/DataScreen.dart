import 'package:async/async.dart';
import 'package:flutter/material.dart';
import '../app_localizations.dart';
import '../component/DeepLinkWidget.dart';
import '../main.dart';
import '../model/MainResponse.dart';
import '../network/NetworkUtils.dart';
import '../screen/DashboardScreen.dart';
import '../screen/ErrorScreen.dart';
import '../screen/SplashScreen.dart';
import '../utils/bloc.dart';
import '../utils/constant.dart';
import '../utils/loader.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart';

class DataScreen extends StatefulWidget {
  static String tag = '/SplashScreen';

  @override
  DataScreenState createState() => DataScreenState();
}

class DataScreenState extends State<DataScreen> {
  bool isWasConnectionLoss = false;
  AsyncMemoizer<MainResponse> mainMemoizer = AsyncMemoizer<MainResponse>();

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    var appLocalization = AppLocalizations.of(context);

    DeepLinkBloc _bloc = DeepLinkBloc();
    return Scaffold(
      backgroundColor: context.cardColor,
      body: Stack(
        children: [
          Provider<DeepLinkBloc>(
            create: (context) => _bloc,
            dispose: (context, bloc) => bloc.dispose(),
            child: DeepLinkWidget(),
          ),
          FutureBuilder<MainResponse>(
            future: mainMemoizer.runOnce(() => fetchData()),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                if (snapshot.data!.toJson().isNotEmpty) {
                  if (snapshot.data!.appconfiguration!.isSplashScreen == "true")
                    return SplashScreen();
                  else
                    return DashBoardScreen();
                } else {
                  return ErrorScreen(error: appLocalization!.translate('msg_add_configuration'));
                }
              } else if (snapshot.hasError) {
                if (PURCHASE_CODE.isNotEmpty) {
                  return ErrorScreen(error: (appLocalization!.translate('msg_wrong_url')!) + " " + (appLocalization.translate('lbl_or')!) + " " + appLocalization.translate('msg_add_configuration')!);
                } else {
                  return ErrorScreen(error: appLocalization!.translate('msg_wrong_url'));
                }
              }
              return Loaders(name: appStore.loaderValues).center().visible(appStore.isLoading);
            },
          ),
        ],
      ),
    );
  }
}
