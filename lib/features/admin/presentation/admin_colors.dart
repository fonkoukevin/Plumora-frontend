import 'package:flutter/material.dart';

/// Fixed dark control-room palette for the Administration space, matching
/// `figma_administration/src/app/screens/AdminPage.tsx` exactly (the `C`
/// object). Unlike the rest of the app, Administration does not follow the
/// user's light/dark preference — it always renders in this palette, which
/// is what the Figma source of truth specifies.
abstract final class AdminColors {
  static const background = Color(0xFF0E1117);
  static const sidebar = Color(0xFF161B22);
  static const card = Color(0xFF1F2633);
  static const border = Color(0xFF2A3142);
  static const primary = Color(0xFF7C5CFF);
  static const accent = Color(0xFFD6B25E);
  static const text = Color(0xFFF4F1EA);
  static const muted = Color(0xFFA8A8B3);
  static const success = Color(0xFF3FBF7F);
  static const error = Color(0xFFE57373);
  static const plumo = Color(0xFFA67CFF);
  static const warning = Color(0xFFF5A623);
}
