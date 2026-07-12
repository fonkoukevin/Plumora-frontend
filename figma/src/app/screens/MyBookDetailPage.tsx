import { useState } from 'react';
import {
  ArrowLeft, PenTool, Edit3, Upload, Trash2, FileText,
  Eye, Check, ChevronRight, MessageSquare, TrendingUp,
  Star, Users, Clock, Globe, Lock, Plus,
  BookOpen, Sparkles, AlertTriangle,
} from 'lucide-react';
import { Story } from '../data/stories';

interface MyBookDetailPageProps {
  book: Story;
  onNavigate: (page: string) => void;
}

const STATUS_MAP = {
  draft:     { label: 'Brouillon', color: '#A8A8B3', bg: 'rgba(168,168,179,0.12)' },
  beta:      { label: 'Bêta-test', color: '#7C5CFF', bg: 'rgba(124,92,255,0.12)' },
  published: { label: 'Publié',    color: '#3FBF7F', bg: 'rgba(63,191,127,0.12)' },
};

const VISIBILITY_MAP = {
  private: { icon: Lock,  label: 'Privé' },
  beta:    { icon: Users, label: 'Bêta uniquement' },
  public:  { icon: Globe, label: 'Public' },
};

export function MyBookDetailPage({ book, onNavigate }: MyBookDetailPageProps) {
  const [activeTab, setActiveTab] = useState<'overview' | 'chapters' | 'stats' | 'settings'>('overview');
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);

  const status = STATUS_MAP[book.status];
  const Vis = VISIBILITY_MAP[book.visibility];
  const publishedChapters = book.chapters.filter((c) => c.published).length;

  return (
    <div className="min-h-screen bg-background pb-8">
      <div className="max-w-3xl mx-auto">

        {/* ── Header ── */}
        <div
          className="sticky top-0 z-30 bg-background/95 border-b border-border px-4 pt-5 pb-3"
          style={{ backdropFilter: 'blur(12px)' }}
        >
          <div className="flex items-center justify-between">
            <button
              onClick={() => onNavigate('write')}
              className="flex items-center gap-1.5 text-sm font-semibold text-primary hover:opacity-80"
            >
              <ArrowLeft className="w-4 h-4" />
              Mes histoires
            </button>
            <button
              onClick={() => onNavigate('editor')}
              className="flex items-center gap-1.5 px-4 py-2 rounded-xl text-sm font-bold text-white shadow-md hover:opacity-90"
              style={{ background: 'linear-gradient(135deg, #7C5CFF, #9B80FF)' }}
            >
              <PenTool className="w-4 h-4" />
              Écrire
            </button>
          </div>
        </div>

        {/* ── Hero cover + info ── */}
        <div className="px-4 pt-6 pb-4">
          <div className="flex gap-5">
            {/* Cover */}
            <div className="relative shrink-0">
              <div className={`w-28 h-40 rounded-2xl bg-gradient-to-br ${book.cover} shadow-xl`}>
                <div className="absolute inset-0 rounded-2xl bg-gradient-to-t from-black/50 via-transparent to-transparent" />
              </div>
              <button
                onClick={() => onNavigate('create-book')}
                className="absolute -bottom-2 -right-2 w-9 h-9 rounded-xl bg-card border border-border shadow-md flex items-center justify-center hover:bg-muted transition-colors"
              >
                <Edit3 className="w-4 h-4 text-muted-foreground" />
              </button>
            </div>

            {/* Info */}
            <div className="flex-1 min-w-0 pt-1">
              <h1
                className="text-xl font-bold text-foreground mb-1 leading-tight"
                style={{ fontFamily: 'var(--font-family-display)' }}
              >
                {book.title}
              </h1>
              <p className="text-sm text-muted-foreground mb-3">{book.genre} · {book.language}</p>

              {/* Status + visibility badges */}
              <div className="flex flex-wrap gap-2 mb-4">
                <span
                  className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-bold"
                  style={{ backgroundColor: status.bg, color: status.color }}
                >
                  <div className="w-1.5 h-1.5 rounded-full" style={{ backgroundColor: status.color }} />
                  {status.label}
                </span>
                <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-muted text-muted-foreground">
                  <Vis.icon className="w-3 h-3" />
                  {Vis.label}
                </span>
              </div>

              {/* Mini stats */}
              <div className="grid grid-cols-3 gap-2">
                {[
                  { label: 'Chapitres', value: `${publishedChapters}/${book.chapters.length}`, icon: FileText },
                  { label: 'Mots', value: `${(book.words / 1000).toFixed(1)}k`, icon: PenTool },
                  { label: 'Modifié', value: book.lastModified.split(',')[0], icon: Clock },
                ].map(({ label, value, icon: Icon }) => (
                  <div key={label} className="bg-card border border-border rounded-xl p-2.5 text-center">
                    <Icon className="w-3.5 h-3.5 text-muted-foreground mx-auto mb-1" />
                    <p className="text-sm font-bold text-foreground">{value}</p>
                    <p className="text-[10px] text-muted-foreground">{label}</p>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Action buttons */}
          <div className="grid grid-cols-3 gap-2 mt-5">
            <button
              onClick={() => onNavigate('editor')}
              className="flex flex-col items-center gap-1.5 py-3 rounded-2xl text-white shadow-md hover:opacity-90 transition-opacity"
              style={{ background: 'linear-gradient(135deg, #7C5CFF, #9B80FF)' }}
            >
              <PenTool className="w-5 h-5" />
              <span className="text-xs font-bold">Écrire</span>
            </button>
            <button
              onClick={() => onNavigate('beta-submission')}
              className="flex flex-col items-center gap-1.5 py-3 rounded-2xl bg-card border border-border hover:bg-muted transition-colors"
            >
              <Users className="w-5 h-5 text-muted-foreground" />
              <span className="text-xs font-semibold text-foreground">Bêta-test</span>
            </button>
            <button
              onClick={() => onNavigate('publication-prep')}
              className="flex flex-col items-center gap-1.5 py-3 rounded-2xl bg-card border border-border hover:bg-muted transition-colors"
            >
              <Upload className="w-5 h-5 text-muted-foreground" />
              <span className="text-xs font-semibold text-foreground">Publier</span>
            </button>
          </div>
        </div>

        {/* ── Tabs ── */}
        <div className="flex gap-1 px-4 mb-4 border-b border-border">
          {(['overview', 'chapters', 'stats', 'settings'] as const).map((tab) => {
            const labels = { overview: 'Aperçu', chapters: 'Chapitres', stats: 'Stats', settings: 'Paramètres' };
            return (
              <button
                key={tab}
                onClick={() => setActiveTab(tab)}
                className={`px-4 py-2.5 text-sm font-semibold border-b-2 transition-colors ${
                  activeTab === tab
                    ? 'border-primary text-primary'
                    : 'border-transparent text-muted-foreground hover:text-foreground'
                }`}
              >
                {labels[tab]}
              </button>
            );
          })}
        </div>

        {/* ══════════ OVERVIEW TAB ══════════ */}
        {activeTab === 'overview' && (
          <div className="px-4 space-y-5">

            {/* Synopsis */}
            <div className="bg-card border border-border rounded-2xl p-5">
              <div className="flex items-center justify-between mb-3">
                <h2 className="font-bold text-foreground">Synopsis</h2>
                <button onClick={() => onNavigate('create-book')} className="text-xs font-semibold text-primary hover:opacity-80">Modifier</button>
              </div>
              <p className="text-sm text-muted-foreground leading-relaxed whitespace-pre-line">
                {book.synopsis || <span className="italic">Aucun résumé encore.</span>}
              </p>
            </div>

            {/* Tags */}
            <div className="bg-card border border-border rounded-2xl p-5">
              <div className="flex items-center justify-between mb-3">
                <h2 className="font-bold text-foreground">Tags</h2>
                <button onClick={() => onNavigate('create-book')} className="text-xs font-semibold text-primary hover:opacity-80">Modifier</button>
              </div>
              <div className="flex flex-wrap gap-2">
                {book.tags.map((tag) => (
                  <span key={tag} className="px-3 py-1 rounded-full text-xs font-medium bg-muted text-muted-foreground">
                    #{tag}
                  </span>
                ))}
              </div>
            </div>


            {/* Mukeme tip */}
            <div
              className="rounded-2xl p-4 border border-border cursor-pointer hover:border-primary/30 transition-colors"
              style={{ background: 'rgba(124,92,255,0.05)' }}
              onClick={() => onNavigate('mukeme')}
            >
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl flex items-center justify-center shrink-0" style={{ background: 'linear-gradient(135deg, #7C5CFF, #9B80FF)' }}>
                  <Sparkles className="w-5 h-5 text-white" />
                </div>
                <div className="flex-1">
                  <p className="text-sm font-bold text-foreground">Idées de Mukeme pour ce livre</p>
                  <p className="text-xs text-muted-foreground mt-0.5">Obtenez des suggestions pour enrichir votre histoire</p>
                </div>
                <ChevronRight className="w-4 h-4 text-muted-foreground" />
              </div>
            </div>
          </div>
        )}

        {/* ══════════ CHAPTERS TAB ══════════ */}
        {activeTab === 'chapters' && (
          <div className="px-4 space-y-3">
            {/* Summary row */}
            <div className="flex items-center justify-between py-1">
              <p className="text-xs text-muted-foreground">
                {publishedChapters} publié{publishedChapters > 1 ? 's' : ''} · {book.chapters.length - publishedChapters} brouillon{book.chapters.length - publishedChapters > 1 ? 's' : ''}
              </p>
              <button
                onClick={() => onNavigate('editor')}
                className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-bold text-white"
                style={{ background: 'linear-gradient(135deg, #7C5CFF, #9B80FF)' }}
              >
                <Plus className="w-3.5 h-3.5" />
                Nouveau chapitre
              </button>
            </div>

            {/* Chapter list */}
            {book.chapters.map((ch, idx) => (
              <div
                key={ch.id}
                className="bg-card border border-border rounded-2xl p-4 flex items-center gap-4 cursor-pointer hover:border-primary/30 transition-all group"
                onClick={() => onNavigate('editor')}
              >
                {/* Number */}
                <div
                  className="w-9 h-9 rounded-xl flex items-center justify-center text-sm font-bold shrink-0"
                  style={ch.published
                    ? { background: 'rgba(63,191,127,0.12)', color: '#3FBF7F' }
                    : { background: 'rgba(168,168,179,0.1)', color: '#A8A8B3' }}
                >
                  {idx + 1}
                </div>

                {/* Info */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    <p className="text-sm font-semibold text-foreground group-hover:text-primary transition-colors truncate">
                      {ch.title}
                    </p>
                    {ch.published ? (
                      <span className="text-[10px] font-bold px-1.5 py-0.5 rounded-full" style={{ background: 'rgba(63,191,127,0.12)', color: '#3FBF7F' }}>
                        Publié
                      </span>
                    ) : (
                      <span className="text-[10px] font-medium px-1.5 py-0.5 rounded-full bg-muted text-muted-foreground">
                        Brouillon
                      </span>
                    )}
                  </div>
                  <div className="flex items-center gap-3 text-xs text-muted-foreground mt-0.5">
                    <span>{ch.words > 0 ? `${ch.words} mots` : 'Vide — à écrire'}</span>
                    <span>· {ch.modifiedAt}</span>
                  </div>
                </div>

                {/* Actions */}
                <div className="flex items-center gap-1 shrink-0">
                  <button
                    onClick={(e) => { e.stopPropagation(); onNavigate('editor'); }}
                    className="w-8 h-8 rounded-lg flex items-center justify-center hover:bg-muted transition-colors"
                    title="Écrire"
                  >
                    <PenTool className="w-4 h-4 text-primary" />
                  </button>
                  <button
                    onClick={(e) => { e.stopPropagation(); onNavigate('editor'); }}
                    className="w-8 h-8 rounded-lg flex items-center justify-center hover:bg-muted transition-colors"
                    title="Lire"
                  >
                    <Eye className="w-4 h-4 text-muted-foreground" />
                  </button>
                </div>
              </div>
            ))}

            {/* Add chapter card */}
            <button
              onClick={() => onNavigate('editor')}
              className="w-full flex items-center justify-center gap-2 p-4 rounded-2xl border-2 border-dashed border-border hover:border-primary/40 hover:bg-muted/30 transition-colors text-muted-foreground hover:text-primary"
            >
              <Plus className="w-5 h-5" />
              <span className="text-sm font-semibold">Ajouter un chapitre</span>
            </button>
          </div>
        )}

        {/* ══════════ STATS TAB ══════════ */}
        {activeTab === 'stats' && (
          <div className="px-4 space-y-4">
            {/* Stats grid */}
            <div className="grid grid-cols-2 gap-3">
              {[
                { icon: BookOpen, label: 'Vues totales', value: book.views || '—', color: '#7C5CFF', sub: 'Depuis la publication' },
                { icon: Star, label: 'Note moyenne', value: book.rating ? `${book.rating}/5` : '—', color: '#D6B25E', sub: 'Pas encore noté' },
                { icon: Users, label: 'Bêta-lecteurs', value: book.betaCount || '—', color: '#3FBF7F', sub: 'En attente' },
                { icon: TrendingUp, label: 'Revenus', value: '—', color: '#A8A8B3', sub: 'Pas encore publié' },
              ].map(({ icon: Icon, label, value, color, sub }) => (
                <div key={label} className="bg-card border border-border rounded-2xl p-4">
                  <div className="w-9 h-9 rounded-xl flex items-center justify-center mb-3" style={{ backgroundColor: `${color}18` }}>
                    <Icon className="w-4 h-4" style={{ color }} />
                  </div>
                  <p className="text-2xl font-bold text-foreground">{value}</p>
                  <p className="text-xs font-semibold text-foreground mt-0.5">{label}</p>
                  <p className="text-[10px] text-muted-foreground mt-0.5">{sub}</p>
                </div>
              ))}
            </div>

            {/* Info tip */}
            <div className="bg-card border border-border rounded-2xl p-4">
              <div className="flex items-start gap-3">
                <TrendingUp className="w-5 h-5 text-muted-foreground shrink-0 mt-0.5" />
                <div>
                  <p className="text-sm font-semibold text-foreground">Les statistiques seront disponibles</p>
                  <p className="text-xs text-muted-foreground mt-1">Publiez votre livre pour voir les vues, notes et revenus en temps réel.</p>
                  <button
                    onClick={() => onNavigate('publication-prep')}
                    className="mt-3 text-xs font-bold text-primary hover:opacity-80"
                  >
                    Préparer la publication →
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* ══════════ SETTINGS TAB ══════════ */}
        {activeTab === 'settings' && (
          <div className="px-4 space-y-4">

            {/* Book info */}
            <div className="bg-card border border-border rounded-2xl overflow-hidden">
              <div className="px-4 py-3 border-b border-border flex items-center justify-between">
                <p className="text-sm font-bold text-foreground">Informations du livre</p>
                <button onClick={() => onNavigate('create-book')} className="text-xs font-semibold text-primary">Modifier</button>
              </div>
              {[
                { label: 'Titre', value: book.title },
                { label: 'Genre', value: book.genre },
                { label: 'Langue', value: book.language },
                { label: 'Créé le', value: book.createdAt },
              ].map(({ label, value }) => (
                <div key={label} className="flex items-center justify-between px-4 py-3 border-b border-border last:border-0">
                  <span className="text-xs text-muted-foreground">{label}</span>
                  <span className="text-xs font-semibold text-foreground">{value}</span>
                </div>
              ))}
            </div>

            {/* Visibility */}
            <div className="bg-card border border-border rounded-2xl overflow-hidden">
              <div className="px-4 py-3 border-b border-border">
                <p className="text-sm font-bold text-foreground">Visibilité</p>
              </div>
              {([
                { id: 'private', icon: Lock,  label: 'Privé', desc: 'Visible uniquement par vous' },
                { id: 'beta',    icon: Users, label: 'Bêta-test', desc: 'Accessible aux bêta-lecteurs' },
                { id: 'public',  icon: Globe, label: 'Public', desc: 'Visible par toute la communauté' },
              ] as const).map(({ id, icon: Icon, label, desc }) => (
                <div key={id} className={`flex items-center gap-3 px-4 py-3 border-b border-border last:border-0 ${book.visibility === id ? '' : 'opacity-60'}`}>
                  <Icon className={`w-4 h-4 shrink-0 ${book.visibility === id ? 'text-primary' : 'text-muted-foreground'}`} />
                  <div className="flex-1">
                    <p className={`text-sm font-semibold ${book.visibility === id ? 'text-foreground' : 'text-muted-foreground'}`}>{label}</p>
                    <p className="text-xs text-muted-foreground">{desc}</p>
                  </div>
                  {book.visibility === id && <Check className="w-4 h-4 text-primary shrink-0" />}
                </div>
              ))}
            </div>

            {/* Mature content */}
            <div className="bg-card border border-border rounded-2xl p-4 flex items-center justify-between">
              <div>
                <p className="text-sm font-semibold text-foreground">Contenu mature</p>
                <p className="text-xs text-muted-foreground">Violence, thèmes adultes (+18)</p>
              </div>
              <div className={`w-12 h-6 rounded-full relative ${book.mature ? 'bg-primary' : 'bg-muted'}`}>
                <div className={`absolute top-1 w-4 h-4 rounded-full bg-white shadow transition-transform ${book.mature ? 'translate-x-7' : 'translate-x-1'}`} />
              </div>
            </div>

            {/* Quick links */}
            <div className="bg-card border border-border rounded-2xl overflow-hidden">
              {[
                { icon: Upload, label: 'Soumettre en bêta-test', page: 'beta-submission', color: '#7C5CFF' },
                { icon: BookOpen, label: 'Préparer la publication', page: 'publication-prep', color: '#D6B25E' },
                { icon: MessageSquare, label: 'Voir les retours bêta', page: 'beta-feedback', color: '#3FBF7F' },
              ].map(({ icon: Icon, label, page, color }) => (
                <button
                  key={label}
                  onClick={() => onNavigate(page)}
                  className="w-full flex items-center gap-3 px-4 py-3.5 border-b border-border last:border-0 hover:bg-muted transition-colors"
                >
                  <div className="w-8 h-8 rounded-lg flex items-center justify-center shrink-0" style={{ backgroundColor: `${color}15` }}>
                    <Icon className="w-4 h-4" style={{ color }} />
                  </div>
                  <span className="text-sm font-semibold text-foreground flex-1 text-left">{label}</span>
                  <ChevronRight className="w-4 h-4 text-muted-foreground" />
                </button>
              ))}
            </div>

            {/* Danger zone */}
            <div className="bg-card border border-destructive/20 rounded-2xl p-4">
              <div className="flex items-center gap-2 mb-3">
                <AlertTriangle className="w-4 h-4 text-destructive" />
                <p className="text-sm font-bold text-destructive">Zone de danger</p>
              </div>
              <p className="text-xs text-muted-foreground mb-4">
                La suppression est irréversible. Tous les chapitres et données associées seront perdus définitivement.
              </p>
              <button
                onClick={() => setShowDeleteConfirm(true)}
                className="w-full py-2.5 rounded-xl border border-destructive/40 text-sm font-bold text-destructive hover:bg-destructive/10 transition-colors"
              >
                Supprimer ce livre
              </button>
            </div>
          </div>
        )}

        <div className="h-8" />
      </div>

      {/* Delete confirm modal */}
      {showDeleteConfirm && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center p-4"
          style={{ background: 'rgba(0,0,0,0.6)', backdropFilter: 'blur(4px)' }}
        >
          <div className="bg-card border border-border rounded-2xl p-6 max-w-sm w-full shadow-2xl">
            <div className="w-12 h-12 rounded-2xl bg-destructive/12 flex items-center justify-center mb-4">
              <Trash2 className="w-6 h-6 text-destructive" />
            </div>
            <h3 className="font-bold text-lg text-foreground mb-2">Supprimer "{book.title}" ?</h3>
            <p className="text-sm text-muted-foreground mb-5">
              Tous les chapitres ({book.chapters.length}), les retours bêta et les données seront supprimés définitivement. Cette action est irréversible.
            </p>
            <div className="flex gap-3">
              <button
                onClick={() => setShowDeleteConfirm(false)}
                className="flex-1 py-3 rounded-xl border border-border text-sm font-semibold hover:bg-muted transition-colors"
              >
                Annuler
              </button>
              <button
                onClick={() => onNavigate('write')}
                className="flex-1 py-3 rounded-xl bg-destructive text-white text-sm font-bold hover:opacity-90 transition-opacity"
              >
                Supprimer
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
