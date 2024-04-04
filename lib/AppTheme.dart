import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';

class AppTheme {
  AppTheme._();

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: false,
    scaffoldBackgroundColor: Colors.white,
    primaryColor: appStore.primaryColors,
    hoverColor: Colors.grey,
    fontFamily: GoogleFonts.poppins().fontFamily,
    appBarTheme: AppBarTheme(
      color: appStore.primaryColors,
     // brightness: appStore.primaryColors.isDark() ? Brightness.dark : Brightness.light,
    ),
    iconTheme: IconThemeData(color: Colors.black),
    cardTheme: CardTheme(color: Colors.white),
  ).copyWith(
    pageTransitionsTheme: PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: OpenUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: false,
    scaffoldBackgroundColor: Color(0xFF131d25),
    appBarTheme: AppBarTheme(
      color: appStore.primaryColors,
      //brightness: appStore.primaryColors.isDark() ? Brightness.dark : Brightness.light,
    ),
    primaryColor: appStore.primaryColors,
    fontFamily: GoogleFonts.poppins().fontFamily,
    cardTheme: CardTheme(color: Color(0xFF1D2939)),
    iconTheme: IconThemeData(color: Colors.white70),
  ).copyWith(
    pageTransitionsTheme: PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: OpenUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
