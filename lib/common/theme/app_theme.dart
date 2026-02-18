import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// FONT
const kSatoshi = 'Satoshi';

// SIZES
const kSizeBody = 14.0;
const kSizeCaption = 12.0;
const kSizeH3 = 16.0;
const kSizeH2 = 20.0;
const kSizeH1 = 28.0;
const kSizeTitle = 40.0;

// COLORS
const kColorPrimary = Color(0xFF2563EB);
const kColorBackground = Color(0xFFF9FAFB);
const kColorFont = Color(0xFF111827);
const kColorFontSecondary = Color(0xFF6B7280);

// TEXT STYLES
const kFontTitle = TextStyle(
  fontFamily: kSatoshi,
  fontWeight: FontWeight.w900,
  color: kColorFont,
  fontSize: kSizeTitle,
);

const kFontH1 = TextStyle(
  fontFamily: kSatoshi,
  fontWeight: FontWeight.w700,
  color: kColorFont,
  fontSize: kSizeH1,
);

const kFontH2 = TextStyle(
  fontFamily: kSatoshi,
  fontWeight: FontWeight.w700,
  color: kColorFont,
  fontSize: kSizeH2,
);

const kFontH3 = TextStyle(
  fontFamily: kSatoshi,
  fontWeight: FontWeight.w500,
  color: kColorFont,
  fontSize: kSizeH3,
);

const kFontBody = TextStyle(
  fontFamily: kSatoshi,
  color: kColorFont,
  fontSize: kSizeBody,
);

const kFontBodyMedium = TextStyle(
  fontFamily: kSatoshi,
  fontWeight: FontWeight.w500,
  color: kColorFont,
  fontSize: kSizeBody,
);

const kFontBodyBold = TextStyle(
  fontFamily: kSatoshi,
  fontWeight: FontWeight.w700,
  color: kColorFont,
  fontSize: kSizeBody,
);

const kFontCaption = TextStyle(
  fontFamily: kSatoshi,
  color: kColorFontSecondary,
  fontSize: kSizeCaption,
);

// THEME
final theme = ThemeData(
  brightness: Brightness.light,
  fontFamily: kSatoshi,
  cupertinoOverrideTheme: const CupertinoThemeData(
    primaryColor: kColorPrimary,
  ),
  textSelectionTheme: const TextSelectionThemeData(
    cursorColor: kColorPrimary,
    selectionColor: kColorPrimary,
    selectionHandleColor: kColorPrimary,
  ),
  snackBarTheme: const SnackBarThemeData(
    backgroundColor: kColorPrimary,
    contentTextStyle: kFontBody,
  ),
  colorScheme: const ColorScheme.light(
    primary: kColorPrimary,
    secondary: kColorPrimary,
    surface: kColorBackground,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: kColorFont,
  ),
  scaffoldBackgroundColor: kColorBackground,
  appBarTheme: const AppBarTheme(
    backgroundColor: kColorBackground,
    foregroundColor: kColorFont,
    elevation: 0,
  ),
  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStateProperty.all(kColorPrimary),
    ),
  ),
);
