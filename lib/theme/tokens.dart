import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

/// `space-*` tokens of the design system.
abstract class Spacing {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 24;
  static const double s6 = 32;
  static const double s7 = 48;
}

/// `radius-*` tokens. [full] is only for the switch, slider thumb and the
/// round transport button.
abstract class Radii {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double full = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius fullAll = BorderRadius.all(Radius.circular(full));
}

/// `size` tokens: layout dimensions and tap targets.
abstract class Sizes {
  static const double targetMin = 40;
  static const double targetLg = 48;
  static const double railWidth = 64;
  static const double railWidthOpen = 224;
  static const double topbarHeight = 56;
  static const double scenesWidth = 280;
  static const double sceneHeaderHeight = 120;
  static const double mixerHeight = 72;
  static const double sfxTileMin = 96;

  static const double rowMin = 56;
  static const double iconSm = 16;
  static const double icon = 20;
  static const double iconLg = 24;
  static const double iconLayer = 22;
  static const double sceneThumb = 40;
  static const double catalogCover = 112;
  static const double catalogCardMax = 320;
  static const double catalogCardMin = 240;
  static const double settingsMaxWidth = 880;
  static const double dialogSm = 440;
  static const double dialogMd = 560;
  static const double dialogLg = 720;
  static const double sliderTrack = 4;
  static const double sliderThumb = 16;
  static const double sliderValueWidth = 36;
  static const double switchWidth = 40;
  static const double switchHeight = 24;
  static const double checkbox = 20;
  static const double chipStatic = 24;
  static const double chipToggle = 32;
  static const double clearButton = 32;
  static const double focusRing = 2;
  static const double borderWidth = 1;
  static const double compactBreakpoint = 700;
  static const double wideBreakpoint = 1000;
  static const double emptyIconBox = 48;
  static const double emptyMessageMax = 360;
  static const double toastWidth = 360;
  static const double equalizerBar = 3;
  static const double equalizerGap = 2;
}

/// `duration-*` tokens.
abstract class Durations {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 320);
  static const Duration tooltipDelay = Duration(milliseconds: 400);
  static const Duration toast = Duration(seconds: 5);
}

/// `easing-*` tokens. Named `Easings` to not clash with Flutter's `Curves`.
abstract class Easings {
  static const Curve standard = Cubic(0.2, 0, 0, 1);
  static const Curve exit = Cubic(0.4, 0, 1, 1);
}

/// `shadow-overlay`: only menus, dialogs and toasts have a shadow.
abstract class Shadows {
  static const List<BoxShadow> overlay = [
    BoxShadow(
      color: Color(0x66000000),
      offset: Offset(0, 8),
      blurRadius: 24,
    ),
  ];
}

/// Colours that are not theme tokens: a fully transparent fill and the black
/// of `shadow-overlay`.
abstract class Palette {
  static const Color transparent = Color(0x00000000);
  static const Color shadow = Color(0xFF000000);
}
