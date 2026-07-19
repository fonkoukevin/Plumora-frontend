import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:google_fonts/google_fonts.dart';

/// Polices disponibles dans les documents Plumora.
///
/// Les valeurs sont persistées dans le Delta. Le rendu passe explicitement
/// par [GoogleFonts] afin qu'une police choisie reste réellement visible sur
/// le Web, le bureau et le mobile, même si elle n'est pas installée sur la
/// machine de l'auteur.
abstract final class PlumoraDocumentFonts {
  static const Map<String, String> toolbarItems = <String, String>{
    'Roman': 'Lora',
    'Classique': 'Merriweather',
    'Élégante': 'Playfair Display',
    'Moderne': 'Inter',
    'Douce': 'Nunito',
    'Machine': 'Roboto Mono',
    'Réinitialiser': 'Clear',
  };

  static TextStyle styleForAttribute(quill.Attribute attribute) {
    if (attribute.key != quill.Attribute.font.key || attribute.value == null) {
      return const TextStyle();
    }

    return switch (attribute.value.toString()) {
      'Lora' || 'Georgia' || 'serif' => GoogleFonts.lora(),
      'Merriweather' => GoogleFonts.merriweather(),
      'Playfair Display' => GoogleFonts.playfairDisplay(),
      'Inter' || 'Arial' || 'sans-serif' => GoogleFonts.inter(),
      'Nunito' || 'Verdana' => GoogleFonts.nunito(),
      'Roboto Mono' || 'Courier New' || 'monospace' => GoogleFonts.robotoMono(),
      final family => TextStyle(fontFamily: family),
    };
  }
}
