import 'package:flutter/material.dart';

/// Fixed light-violet control-room palette for the Administration space,
/// matching `figma_administration/src/app/screens/AdminPage.tsx` exactly
/// (the `C` object). Unlike the rest of the app, Administration does not
/// follow the user's light/dark preference — it always renders in this
/// palette, which is what the Figma source of truth specifies.
abstract final class AdminColors {
  static const background = Color(0xFFF5F3FF);
  static const surface = Color(0xFFFFFFFF);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFDDD8FF);
  static const text = Color(0xFF1A1040);
  static const muted = Color(0xFF7167A0);
  static const primary = Color(0xFF7C5CFF);

  /// Distinct from [plumo] (the AI assistant's brand color) — this one
  /// marks Plumora-native works (as opposed to public-domain imports).
  static const plumora = Color(0xFF9B6FD4);
  static const plumo = Color(0xFFA67CFF);
  static const error = Color(0xFFE57373);
  static const success = Color(0xFF3FBF7F);
  static const warning = Color(0xFFF5A623);
}
