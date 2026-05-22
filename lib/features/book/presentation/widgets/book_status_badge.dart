import 'package:flutter/material.dart';

import '../../../../core/theme/plumora_colors.dart';
import '../../../../core/widgets/plumora_ui.dart';
import '../../data/models/book_model.dart';

class BookStatusBadge extends StatelessWidget {
  const BookStatusBadge({required this.status, super.key});

  final BookStatus status;

  @override
  Widget build(BuildContext context) {
    return PlumoraBadge(
      label: status.label,
      backgroundColor: status.backgroundColor,
      foregroundColor: status.foregroundColor,
    );
  }
}

extension BookStatusUi on BookStatus {
  String get label {
    switch (this) {
      case BookStatus.draft:
        return 'DRAFT';
      case BookStatus.inBetaReading:
        return 'IN_BETA_READING';
      case BookStatus.inCorrection:
        return 'IN_CORRECTION';
      case BookStatus.readyToPublish:
        return 'READY_TO_PUBLISH';
      case BookStatus.published:
        return 'PUBLISHED';
      case BookStatus.archived:
        return 'ARCHIVED';
      case BookStatus.unknown:
        return 'UNKNOWN';
    }
  }

  String get frenchLabel {
    switch (this) {
      case BookStatus.draft:
        return 'Brouillon';
      case BookStatus.inBetaReading:
        return 'Bêta-lecture';
      case BookStatus.inCorrection:
        return 'Correction';
      case BookStatus.readyToPublish:
        return 'Prêt à publier';
      case BookStatus.published:
        return 'Publié';
      case BookStatus.archived:
        return 'Archivé';
      case BookStatus.unknown:
        return 'Inconnu';
    }
  }

  String get shortFrenchLabel {
    switch (this) {
      case BookStatus.draft:
        return 'Brouillon';
      case BookStatus.inBetaReading:
        return 'Bêta-test';
      case BookStatus.inCorrection:
        return 'Correction';
      case BookStatus.readyToPublish:
        return 'Prêt';
      case BookStatus.published:
        return 'Publié';
      case BookStatus.archived:
        return 'Archivé';
      case BookStatus.unknown:
        return 'Inconnu';
    }
  }

  IconData get smallIcon {
    switch (this) {
      case BookStatus.draft:
        return Icons.edit_outlined;
      case BookStatus.inBetaReading:
        return Icons.search;
      case BookStatus.inCorrection:
        return Icons.build_outlined;
      case BookStatus.readyToPublish:
        return Icons.check_box;
      case BookStatus.published:
        return Icons.celebration_outlined;
      case BookStatus.archived:
        return Icons.archive_outlined;
      case BookStatus.unknown:
        return Icons.help_outline;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case BookStatus.draft:
        return const Color(0xFFF1E8D8);
      case BookStatus.inBetaReading:
        return const Color(0xFFE8F0F5);
      case BookStatus.inCorrection:
        return const Color(0xFFF8E6D2);
      case BookStatus.readyToPublish:
        return const Color(0xFFE6F0E7);
      case BookStatus.published:
        return const Color(0xFFE6EFE4);
      case BookStatus.archived:
        return PlumoraColors.muted;
      case BookStatus.unknown:
        return const Color(0xFFF7E0DC);
    }
  }

  Color get foregroundColor {
    switch (this) {
      case BookStatus.draft:
        return const Color(0xFF8E7345);
      case BookStatus.inBetaReading:
        return PlumoraColors.info;
      case BookStatus.inCorrection:
        return const Color(0xFFA4683E);
      case BookStatus.readyToPublish:
        return PlumoraColors.success;
      case BookStatus.published:
        return PlumoraColors.mukemeAccent;
      case BookStatus.archived:
        return PlumoraColors.textSecondary;
      case BookStatus.unknown:
        return PlumoraColors.destructive;
    }
  }
}
