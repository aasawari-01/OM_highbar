class AppConstants {
  // ── Padding ────────────────────────────────────────────────
  static const double screenPadding = 16.0;
  static const double cardPadding = 16.0;
  static const double horizontalPadding = 16.0;
  static const double verticalPadding = 12.0;

  // ── Spacing ─────────────────────────────────────────────────
  static const double sectionSpacing = 20.0;
  static const double elementSpacing = 16.0;
  static const double labelSpacing = 8.0;
  static const double subElementSpacing = 8.0;
  static const double headerSpacing = 30.0;

  // ── Typography ───────────────────────────────────────────────
  static const double sectionHeaderSize = 25;
  static const double sectionHeaderValue = 24;
  static const double headerSize = 20;
  static const double appBarTextSize = 20;
  static const double textSize = 16;
  static const double formLabelSize = 16;
  static const double bodySize = 15;
  static const double subtitleSize = 12;
  static const double detailLabelSize = 14;
  static const double detailValueSize = 14;

  // ── Radius ───────────────────────────────────────────────────
  static const double cardRadius = 12.0;
  static const double inputRadius = 4.0;

  // ── Input Fields ─────────────────────────────────────────────
  static const double inputHeight = 40.0;
  static const double iconSize = 20;

  // ── Buttons ──────────────────────────────────────────────────
  static const double buttonHeight = 40.0;
  static const double buttonFontSize = 14.0;

  // ── Durations ────────────────────────────────────────────────
  static const Duration snackbarDuration = Duration(seconds: 3);
  static const Duration apiTimeout = Duration(seconds: 60);
  static const Duration apiMultipartTimeout = Duration(seconds: 120);

  // ── Legacy aliases (kept for backward compatibility) ─────────
  // ignore: constant_identifier_names
  static const double HeaderSize = headerSize;
  // ignore: constant_identifier_names
  static const double appbarText = appBarTextSize;
  // ignore: constant_identifier_names
  static const double subtitles = subtitleSize;
  // ignore: constant_identifier_names
  static const double sectionHeadervalue = sectionHeaderValue;
}
