import 'package:flutter/material.dart';

const Color appBgDark = Color(0xFF050505);
const Color appBgLight = Color(0xFF1a1a1a);
const Color accentYellow = Color(0xFFFACC15);

final ThemeData appTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: accentYellow,
  scaffoldBackgroundColor: appBgDark,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.black,
    elevation: 0,
    centerTitle: false,
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: appBgLight,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
  ),
  colorScheme: const ColorScheme.dark(
    primary: accentYellow,
    surface: appBgLight,
  ),
  useMaterial3: true,
);

class AppColors {
  static const LinearGradient bgGradient = LinearGradient(
    colors: [appBgDark, appBgLight],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
