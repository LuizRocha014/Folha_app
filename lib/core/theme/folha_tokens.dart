/// Folha — tokens não-cromáticos / não-tipográficos (espaçamento, raios, durações).
class FolhaSpacing {
  FolhaSpacing._();
  static const double s0 = 0;
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s7 = 32;
  static const double s8 = 40;
  static const double s9 = 56;
  static const double s10 = 72;
  static const double s11 = 96;
}

class FolhaRadius {
  FolhaRadius._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 18;
  static const double xl = 28;
  static const double pill = 999;
}

class FolhaDuration {
  FolhaDuration._();
  static const fast = Duration(milliseconds: 140);
  static const med = Duration(milliseconds: 240);
  static const slow = Duration(milliseconds: 420);
}
