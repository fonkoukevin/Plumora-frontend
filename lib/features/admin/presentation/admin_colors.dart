import 'package:flutter/material.dart';

/// Fixed light control-room palette for the Administration space. Unlike the
/// rest of the app, Administration does not follow the user's light/dark
/// preference. Its main surface stays white while violet remains the accent.
abstract final class AdminColors {
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFDDD8FF);
  static const text = Color(0xFF1A1040);
  static const muted = Color(0xFF7167A0);

  /// Pale tint used for hover states and muted chips -- distinct from
  /// [muted], which is the muted *text* color.
  static const mutedBg = Color(0xFFF0EEFF);
  static const primary = Color(0xFF7C5CFF);

  /// Pale tint of [primary], used for active nav backgrounds and badges.
  static const primaryBg = Color(0xFFEDE9FF);

  /// Distinct from [plumo] (the AI assistant's brand color) — this one
  /// marks Plumora-native works (as opposed to public-domain imports).
  static const plumora = Color(0xFF9B6FD4);
  static const plumo = Color(0xFFA67CFF);
  static const error = Color(0xFFE05252);
  static const success = Color(0xFF2EA87A);
  static const warning = Color(0xFFD97706);
}
