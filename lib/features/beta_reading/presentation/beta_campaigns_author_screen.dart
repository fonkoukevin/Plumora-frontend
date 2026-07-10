import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/plumora_colors.dart';
import '../../../core/widgets/plumora_ui.dart';
import '../../book/data/models/book_model.dart';
import '../../book/data/models/chapter_model.dart';
import '../../book/data/repositories/book_repository.dart';
import '../../book/data/repositories/chapter_repository.dart';
import '../../book/presentation/widgets/book_status_badge.dart';
import '../data/models/beta_campaign_model.dart';
import '../data/models/beta_reader_summary_model.dart';
import '../data/repositories/beta_reading_repository.dart';

class BetaCampaignsAuthorScreen extends ConsumerStatefulWidget {
  const BetaCampaignsAuthorScreen({required this.bookId, super.key});

  final String bookId;

  @override
  ConsumerState<BetaCampaignsAuthorScreen> createState() =>
      _BetaCampaignsAuthorScreenState();
}

class _BetaCampaignsAuthorScreenState
    extends ConsumerState<BetaCampaignsAuthorScreen> {
  final _titleController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _inviteesController = TextEditingController();
  final Set<String> _selectedChapterIds = {};
  final Set<String> _selectedReaderIds = {};
  String? _initializedBookId;
  bool _isSubmitting = false;
  String? _busyCampaignId;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _instructionsController.dispose();
    _deadlineController.dispose();
    _inviteesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookAsync = ref.watch(authorBookProvider(widget.bookId));
    final chaptersAsync = ref.watch(bookChaptersProvider(widget.bookId));
    final campaignsAsync = ref.watch(
      betaCampaignsForBookProvider(widget.bookId),
    );
    final readersAsync = ref.watch(betaReaderOptionsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 760 ? 32.0 : 16.0;
        final bottomPadding = constraints.maxWidth >= 900 ? 32.0 : 92.0;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            28,
            horizontal,
            bottomPadding,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: bookAsync.when(
                loading: () => const _LoadingCard(),
                error: (error, _) => _StateCard(
                  title: 'Livre introuvable',
                  subtitle: AppError.messageFor(error),
                  action: FilledButton(
                    onPressed: () =>
                        ref.invalidate(authorBookProvider(widget.bookId)),
                    child: const Text('Réessayer'),
                  ),
                ),
                data: (book) => chaptersAsync.when(
                  loading: () => const _LoadingCard(),
                  error: (error, _) => _StateCard(
                    title: 'Chapitres indisponibles',
                    subtitle: AppError.messageFor(error),
                    action: FilledButton(
                      onPressed: () =>
                          ref.invalidate(bookChaptersProvider(widget.bookId)),
                      child: const Text('Réessayer'),
                    ),
                  ),
                  data: (chapters) {
                    _initializeChapters(book.id, chapters);
                    if (_titleController.text.trim().isEmpty) {
                      _titleController.text =
                          'Bêta-test - ${book.title.isEmpty ? 'Manuscrit' : book.title}';
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton.icon(
                          onPressed: _isSubmitting
                              ? null
                              : () => context.go(
                                  AppRoutes.authorBookDetailPath(book.id),
                                ),
                          icon: const Icon(Icons.arrow_back, size: 16),
                          label: const Text('Retour'),
                        ),
                        const SizedBox(height: 22),
                        _Header(book: book),
                        const SizedBox(height: 24),
                        _CampaignForm(
                          titleController: _titleController,
                          instructionsController: _instructionsController,
                          deadlineController: _deadlineController,
                          inviteesController: _inviteesController,
                          chapters: chapters,
                          selectedChapterIds: _selectedChapterIds,
                          readersAsync: readersAsync,
                          selectedReaderIds: _selectedReaderIds,
                          isSubmitting: _isSubmitting,
                          error: _error,
                          onToggleChapter: _toggleChapter,
                          onToggleReader: _toggleReader,
                          onSubmit: chapters.isEmpty ? null : _createCampaign,
                        ),
                        const SizedBox(height: 26),
                        _CampaignList(
                          campaignsAsync: campaignsAsync,
                          busyCampaignId: _busyCampaignId,
                          onRetry: () => ref.invalidate(
                            betaCampaignsForBookProvider(widget.bookId),
                          ),
                          onClose: _closeCampaign,
                          onCancel: _cancelCampaign,
                          onComments: (campaign) => context.go(
                            AppRoutes.authorBetaCommentsPath(book.id),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _initializeChapters(String bookId, List<ChapterModel> chapters) {
    if (_initializedBookId == bookId) {
      return;
    }

    _initializedBookId = bookId;
    _selectedChapterIds
      ..clear()
      ..addAll(chapters.map((chapter) => chapter.id));
  }

  void _toggleChapter(String chapterId) {
    setState(() {
      if (_selectedChapterIds.contains(chapterId)) {
        _selectedChapterIds.remove(chapterId);
      } else {
        _selectedChapterIds.add(chapterId);
      }
    });
  }

  void _toggleReader(String readerId) {
    setState(() {
      if (_selectedReaderIds.contains(readerId)) {
        _selectedReaderIds.remove(readerId);
      } else {
        _selectedReaderIds.add(readerId);
      }
    });
  }

  Future<void> _createCampaign() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _selectedChapterIds.isEmpty) {
      setState(() {
        _error = 'Ajoute un titre et sélectionne au moins un chapitre.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final repository = ref.read(betaReadingRepositoryProvider);
      final campaign = await repository.createCampaign(
        widget.bookId,
        BetaCampaignCreateRequest(
          title: title,
          instructions: _instructionsController.text,
          deadline: _parseDeadline(_deadlineController.text),
        ),
      );
      if (_selectedChapterIds.isNotEmpty) {
        await repository.updateSharedChapters(
          campaign.id,
          _selectedChapterIds.toList(),
        );
      }

      for (final invitee in _readInvitees()) {
        await repository.createInvitation(campaign.id, invitee);
      }
      final skipped = _readInvalidInvitees();

      ref.invalidate(betaCampaignsForBookProvider(widget.bookId));
      ref.invalidate(myBooksProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              skipped.isEmpty
                  ? 'Campagne bêta créée.'
                  : 'Campagne bêta créée. Non invités (identifiant invalide) : '
                        '${skipped.join(', ')}',
            ),
          ),
        );
      }
    } catch (error) {
      setState(() => _error = AppError.messageFor(error));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _closeCampaign(BetaCampaignModel campaign) async {
    setState(() => _busyCampaignId = campaign.id);
    try {
      await ref.read(betaReadingRepositoryProvider).closeCampaign(campaign.id);
      ref.invalidate(betaCampaignsForBookProvider(widget.bookId));
      ref.invalidate(betaCampaignProvider(campaign.id));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppError.messageFor(error))));
      }
    } finally {
      if (mounted) {
        setState(() => _busyCampaignId = null);
      }
    }
  }

  Future<void> _cancelCampaign(BetaCampaignModel campaign) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler cette campagne ?'),
        content: const Text(
          "Les bêta-lecteurs ne pourront plus lire ni commenter cette "
          "campagne. Cette action n'est pas réversible.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Retour'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Annuler la campagne'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    setState(() => _busyCampaignId = campaign.id);
    try {
      await ref.read(betaReadingRepositoryProvider).cancelCampaign(campaign.id);
      ref.invalidate(betaCampaignsForBookProvider(widget.bookId));
      ref.invalidate(betaCampaignProvider(campaign.id));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppError.messageFor(error))));
      }
    } finally {
      if (mounted) {
        setState(() => _busyCampaignId = null);
      }
    }
  }

  static final _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  List<BetaInvitationCreateRequest> _readInvitees() {
    final fromText = _parseInviteeTokens(
      _inviteesController.text,
    ).where(_uuidPattern.hasMatch);
    final ids = {...fromText, ..._selectedReaderIds};
    return ids
        .map((value) => BetaInvitationCreateRequest(betaReaderId: value))
        .toList(growable: false);
  }

  List<String> _readInvalidInvitees() {
    return _parseInviteeTokens(
      _inviteesController.text,
    ).where((value) => !_uuidPattern.hasMatch(value)).toList(growable: false);
  }

  DateTime? _parseDeadline(String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) {
      return null;
    }

    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return parsed;
    }

    final french = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(value);
    if (french == null) {
      return null;
    }

    return DateTime(
      int.parse(french.group(3)!),
      int.parse(french.group(2)!),
      int.parse(french.group(1)!),
    );
  }
}

List<String> _parseInviteeTokens(String raw) {
  return raw
      .split(RegExp(r'[,;\n]'))
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
}

class _Header extends StatelessWidget {
  const _Header({required this.book});

  final BookModel book;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PlumoraIconTile(
            backgroundColor: PlumoraColors.info,
            child: Icon(Icons.groups_outlined, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Envoyer en bêta-test',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: PlumoraColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  book.title.isEmpty ? 'Livre sans titre' : book.title,
                  style: const TextStyle(
                    color: PlumoraColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                BookStatusBadge(status: book.status),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignForm extends StatelessWidget {
  const _CampaignForm({
    required this.titleController,
    required this.instructionsController,
    required this.deadlineController,
    required this.inviteesController,
    required this.chapters,
    required this.selectedChapterIds,
    required this.readersAsync,
    required this.selectedReaderIds,
    required this.isSubmitting,
    required this.onToggleChapter,
    required this.onToggleReader,
    required this.onSubmit,
    this.error,
  });

  final TextEditingController titleController;
  final TextEditingController instructionsController;
  final TextEditingController deadlineController;
  final TextEditingController inviteesController;
  final List<ChapterModel> chapters;
  final Set<String> selectedChapterIds;
  final AsyncValue<List<BetaReaderSummaryModel>> readersAsync;
  final Set<String> selectedReaderIds;
  final bool isSubmitting;
  final ValueChanged<String> onToggleChapter;
  final ValueChanged<String> onToggleReader;
  final VoidCallback? onSubmit;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Nouvelle campagne',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: titleController,
            enabled: !isSubmitting,
            decoration: const InputDecoration(labelText: 'Titre'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: deadlineController,
            enabled: !isSubmitting,
            decoration: const InputDecoration(
              labelText: 'Deadline',
              hintText: '2026-06-12 ou 12/06/2026',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: instructionsController,
            enabled: !isSubmitting,
            minLines: 4,
            maxLines: 7,
            decoration: const InputDecoration(
              labelText: 'Consignes pour les bêta-lecteurs',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Chapitres à partager',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          if (chapters.isEmpty)
            const Text(
              'Crée au moins un chapitre avant de lancer une bêta-lecture.',
              style: TextStyle(color: PlumoraColors.textSecondary),
            )
          else
            for (final chapter in chapters) ...[
              CheckboxListTile(
                value: selectedChapterIds.contains(chapter.id),
                onChanged: isSubmitting
                    ? null
                    : (_) => onToggleChapter(chapter.id),
                title: Text(
                  chapter.title.isEmpty ? 'Chapitre sans titre' : chapter.title,
                ),
                subtitle: Text(
                  chapter.order == 0 ? 'Chapitre' : 'Chapitre ${chapter.order}',
                ),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          const SizedBox(height: 18),
          const Text(
            'Inviter des bêta-lecteurs (optionnel)',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            "Tout bêta-lecteur peut déjà rejoindre la campagne sans "
            "invitation — ceci n'envoie qu'une notification ciblée.",
            style: TextStyle(color: PlumoraColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 10),
          readersAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            ),
            error: (error, _) => Text(
              AppError.messageFor(error),
              style: const TextStyle(color: PlumoraColors.textSecondary),
            ),
            data: (readers) => readers.isEmpty
                ? const Text(
                    'Aucun bêta-lecteur enregistré pour le moment.',
                    style: TextStyle(color: PlumoraColors.textSecondary),
                  )
                : _ReaderPicker(
                    readers: readers,
                    selectedIds: selectedReaderIds,
                    onToggle: onToggleReader,
                    enabled: !isSubmitting,
                  ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: inviteesController,
            enabled: !isSubmitting,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Ou saisir des identifiants directement',
              hintText:
                  'Identifiants (UUID) des bêta-lecteurs, séparés par des '
                  "virgules — utile si la personne n'apparaît pas dans la liste.",
              alignLabelWithHint: true,
            ),
          ),
          ListenableBuilder(
            listenable: inviteesController,
            builder: (context, _) {
              final invitees = _parseInviteeTokens(inviteesController.text);
              if (invitees.isEmpty) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final invitee in invitees)
                      Chip(
                        avatar: const Icon(Icons.person_outline, size: 16),
                        label: Text(invitee),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              );
            },
          ),
          if (error != null) ...[
            const SizedBox(height: 14),
            Text(
              error!,
              style: const TextStyle(
                color: PlumoraColors.destructive,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: isSubmitting ? null : onSubmit,
            icon: isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_outlined, size: 18),
            label: Text(
              isSubmitting ? 'Création...' : 'Créer et envoyer en bêta-test',
            ),
          ),
        ],
      ),
    );
  }
}

class _ReaderPicker extends StatefulWidget {
  const _ReaderPicker({
    required this.readers,
    required this.selectedIds,
    required this.onToggle,
    required this.enabled,
  });

  final List<BetaReaderSummaryModel> readers;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;
  final bool enabled;

  @override
  State<_ReaderPicker> createState() => _ReaderPickerState();
}

class _ReaderPickerState extends State<_ReaderPicker> {
  TextEditingController? _fieldController;

  @override
  Widget build(BuildContext context) {
    final selected = widget.readers
        .where((reader) => widget.selectedIds.contains(reader.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Autocomplete<BetaReaderSummaryModel>(
          optionsBuilder: (textEditingValue) {
            if (!widget.enabled) {
              return const Iterable<BetaReaderSummaryModel>.empty();
            }
            final query = textEditingValue.text.trim().toLowerCase();
            return widget.readers.where((reader) {
              if (widget.selectedIds.contains(reader.id)) {
                return false;
              }
              return query.isEmpty ||
                  reader.username.toLowerCase().contains(query);
            });
          },
          displayStringForOption: (reader) => reader.username,
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            _fieldController = controller;
            return TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: widget.enabled,
              decoration: const InputDecoration(
                labelText: 'Rechercher un bêta-lecteur',
                hintText: 'Nom d\'utilisateur...',
                prefixIcon: Icon(Icons.search),
              ),
            );
          },
          onSelected: (reader) {
            widget.onToggle(reader.id);
            _fieldController?.clear();
          },
        ),
        if (selected.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final reader in selected)
                Chip(
                  avatar: const Icon(Icons.person, size: 16),
                  label: Text(reader.username),
                  visualDensity: VisualDensity.compact,
                  onDeleted: widget.enabled
                      ? () => widget.onToggle(reader.id)
                      : null,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _CampaignList extends StatelessWidget {
  const _CampaignList({
    required this.campaignsAsync,
    required this.busyCampaignId,
    required this.onRetry,
    required this.onClose,
    required this.onCancel,
    required this.onComments,
  });

  final AsyncValue<List<BetaCampaignModel>> campaignsAsync;
  final String? busyCampaignId;
  final VoidCallback onRetry;
  final ValueChanged<BetaCampaignModel> onClose;
  final ValueChanged<BetaCampaignModel> onCancel;
  final ValueChanged<BetaCampaignModel> onComments;

  @override
  Widget build(BuildContext context) {
    return campaignsAsync.when(
      loading: () => const _LoadingCard(),
      error: (error, _) => _StateCard(
        title: 'Campagnes indisponibles',
        subtitle: AppError.messageFor(error),
        action: FilledButton(
          onPressed: onRetry,
          child: const Text('Réessayer'),
        ),
      ),
      data: (campaigns) {
        if (campaigns.isEmpty) {
          return const _StateCard(
            title: 'Aucune campagne bêta',
            subtitle:
                'Les campagnes créées pour ce livre apparaîtront ici avec leurs retours.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Campagnes existantes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            for (final campaign in campaigns) ...[
              PlumoraCard(
                onTap: () => context.go(
                  AppRoutes.authorBetaCampaignDetailPath(
                    campaign.id,
                    bookId: campaign.bookId,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PlumoraIconTile(
                      backgroundColor:
                          campaign.status == BetaCampaignStatus.active
                          ? const Color(0xFFE8F0F5)
                          : PlumoraColors.muted,
                      child: Icon(
                        campaign.status == BetaCampaignStatus.active
                            ? Icons.groups_outlined
                            : Icons.lock_outline,
                        color: campaign.status == BetaCampaignStatus.active
                            ? PlumoraColors.info
                            : PlumoraColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            campaign.bookTitle.isEmpty
                                ? 'Campagne bêta'
                                : campaign.bookTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            campaign.instructions?.isNotEmpty == true
                                ? campaign.instructions!
                                : 'Aucune consigne renseignée.',
                            style: const TextStyle(
                              color: PlumoraColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              PlumoraBadge(label: campaign.status.label),
                              if (campaign.deadline != null)
                                PlumoraBadge(
                                  label: _dateLabel(campaign.deadline!),
                                  backgroundColor: PlumoraColors.muted,
                                  foregroundColor: PlumoraColors.textSecondary,
                                  icon: Icons.schedule,
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => context.go(
                                  AppRoutes.authorBetaCampaignDetailPath(
                                    campaign.id,
                                    bookId: campaign.bookId,
                                  ),
                                ),
                                icon: const Icon(Icons.open_in_new, size: 17),
                                label: const Text('Détail'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => onComments(campaign),
                                icon: const Icon(
                                  Icons.forum_outlined,
                                  size: 17,
                                ),
                                label: const Text('Voir les retours'),
                              ),
                              if (campaign.status ==
                                  BetaCampaignStatus.active) ...[
                                TextButton(
                                  onPressed: busyCampaignId == campaign.id
                                      ? null
                                      : () => onClose(campaign),
                                  child: Text(
                                    busyCampaignId == campaign.id
                                        ? 'Fermeture...'
                                        : 'Fermer',
                                  ),
                                ),
                                TextButton(
                                  onPressed: busyCampaignId == campaign.id
                                      ? null
                                      : () => onCancel(campaign),
                                  style: TextButton.styleFrom(
                                    foregroundColor: PlumoraColors.destructive,
                                  ),
                                  child: Text(
                                    busyCampaignId == campaign.id
                                        ? 'Annulation...'
                                        : 'Annuler',
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({required this.title, required this.subtitle, this.action});

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return PlumoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: PlumoraColors.textSecondary),
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

String _dateLabel(DateTime date) {
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
}
