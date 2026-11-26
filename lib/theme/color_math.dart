import 'dart:math' as math;

/// Pure colour maths on 0xAARRGGBB ints (no Flutter imports, so it can be
/// used from tools and tests). Used to derive the dependent theme tokens
/// from the eight colours a user picks in the theme editor.
class Oklch {
  final double l;
  final double c;
  final double h;
  const Oklch(this.l, this.c, this.h);
}

double _lin(int v) {
  final s = v / 255.0;
  return s <= 0.04045 ? s / 12.92 : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
}

double _delin(double v) {
  final s = v <= 0.0031308 ? v * 12.92 : 1.055 * math.pow(v, 1 / 2.4) - 0.055;
  return s;
}

int _r(int argb) => (argb >> 16) & 0xFF;
int _g(int argb) => (argb >> 8) & 0xFF;
int _b(int argb) => argb & 0xFF;

int rgb(int r, int g, int b) => 0xFF000000 | (r << 16) | (g << 8) | b;

Oklch toOklch(int argb) {
  final r = _lin(_r(argb));
  final g = _lin(_g(argb));
  final b = _lin(_b(argb));
  final l = math.pow(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b, 1 / 3);
  final m = math.pow(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b, 1 / 3);
  final s = math.pow(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b, 1 / 3);
  final okL = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s;
  final okA = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s;
  final okB = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s;
  return Oklch(okL, math.sqrt(okA * okA + okB * okB), math.atan2(okB, okA));
}

/// Returns null when the colour is outside the sRGB gamut.
int? _tryFromOklch(double okL, double c, double h) {
  final a = c * math.cos(h);
  final b = c * math.sin(h);
  final l = math.pow(okL + 0.3963377774 * a + 0.2158037573 * b, 3).toDouble();
  final m = math.pow(okL - 0.1055613458 * a - 0.0638541728 * b, 3).toDouble();
  final s = math.pow(okL - 0.0894841775 * a - 1.2914855480 * b, 3).toDouble();
  final r = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s;
  final g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s;
  final bl = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s;
  const eps = 0.0005;
  if (r < -eps || r > 1 + eps || g < -eps || g > 1 + eps || bl < -eps || bl > 1 + eps) {
    return null;
  }
  int ch(double v) => (_delin(v.clamp(0.0, 1.0)) * 255).round().clamp(0, 255);
  return rgb(ch(r), ch(g), ch(bl));
}

/// Builds a colour from OKLCH, lowering chroma until it fits in sRGB.
int fromOklch(double okL, double c, double h) {
  final lc = okL.clamp(0.0, 1.0);
  var chroma = c;
  for (var i = 0; i < 40; i++) {
    final v = _tryFromOklch(lc, chroma, h);
    if (v != null) return v;
    chroma *= 0.92;
  }
  return _tryFromOklch(lc, 0, h) ?? 0xFF000000;
}

/// Shifts lightness by [delta] keeping hue and chroma.
int shiftLightness(int argb, double delta) {
  final o = toOklch(argb);
  return fromOklch(o.l + delta, o.c, o.h);
}

double luminance(int argb) {
  return 0.2126 * _lin(_r(argb)) + 0.7152 * _lin(_g(argb)) + 0.0722 * _lin(_b(argb));
}

double contrastRatio(int a, int b) {
  final la = luminance(a);
  final lb = luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

/// `amount` of [a] over [b] (0..1), opaque result.
int mix(int a, int b, double amount) {
  int ch(int x, int y) => (x * amount + y * (1 - amount)).round().clamp(0, 255);
  return rgb(ch(_r(a), _r(b)), ch(_g(a), _g(b)), ch(_b(a), _b(b)));
}

bool isDarkColor(int argb) => toOklch(argb).l < 0.5;

/// Moves [argb] lightness (up when [lighter], else down) until its contrast
/// to every colour in [against] reaches [ratio]. Stops at white/black.
int adjustToContrast(int argb, List<int> against, double ratio, {required bool lighter}) {
  var o = toOklch(argb);
  var current = argb;
  for (var i = 0; i < 120; i++) {
    if (against.every((bg) => contrastRatio(current, bg) >= ratio)) return current;
    final next = o.l + (lighter ? 0.01 : -0.01);
    if (next > 1 || next < 0) return current;
    o = Oklch(next, o.c, o.h);
    current = fromOklch(o.l, o.c, o.h);
  }
  return current;
}

int bestOnColor(int background) {
  const white = 0xFFFFFFFF;
  const black = 0xFF000000;
  return contrastRatio(white, background) >= contrastRatio(black, background) ? white : black;
}
