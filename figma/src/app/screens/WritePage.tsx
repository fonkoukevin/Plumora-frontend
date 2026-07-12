import { useState } from 'react';
import { MobileNav } from '../components/MobileNav';
import {
  Plus, PenTool, BookOpen, MoreHorizontal, Clock, FileText,
  Eye, MessageSquare, Upload, ChevronRight, Sparkles, Users,
  TrendingUp, Edit3, Trash2, Star,
} from 'lucide-react';
import { STORIES as ALL_STORIES } from '../data/stories';

interface WritePageProps {
  onNavigate: (page: string) => void;
}

const STATUS_CONFIG = {
  draft:     { label: 'Brouillon', bg: 'rgba(168,168,179,0.15)', color: '#A8A8B3', dot: '#A8A8B3' },
  beta:      { label: 'Bêta-test', bg: 'rgba(124,92,255,0.12)', color: '#7C5CFF', dot: '#7C5CFF' },
  published: { label: 'Publié',    bg: 'rgba(63,191,127,0.12)', color: '#3FBF7F', dot: '#3FBF7F' },
};

const TABS = ['Toutes', 'En cours', 'Bêta-test', 'Publiées'];

function StoryCard({
  story,
  onNavigate,
  onDelete,
}: {
  story: typeof ALL_STORIES[0];
  onNavigate: (p: string) => void;
  onDelete: (id: number) => void;
}) {
  const [menuOpen, setMenuOpen] = useState(false);
  const status = STATUS_CONFIG[story.status as keyof typeof STATUS_CONFIG];

  return (
    <div className="bg-card border border-border rounded-2xl overflow-hidden hover:border-primary/30 hover:shadow-lg transition-all group relative">
      <div className="flex gap-4 p-4">
        {/* Cover */}
        <div
          className={`w-20 h-28 md:w-24 md:h-36 rounded-xl bg-gradient-to-br ${story.cover} shrink-0 shadow-lg group-hover:scale-105 transition-transform relative overflow-hidden`}
          onClick={() => onNavigate(`my-book-detail-${story.id}`)}
          style={{ cursor: 'pointer' }}
        >
          <div className="absolute inset-0 bg-gradient-to-t from-black/50 via-transparent to-transparent" />
          <div className="absolute bottom-1.5 left-1.5 right-1.5">
            <p className="text-white text-[9px] font-bold leading-tight line-clamp-2">{story.title}</p>
          </div>
        </div>

        {/* Info */}
        <div className="flex-1 min-w-0">
          {/* Title + menu */}
          <div className="flex items-start justify-between gap-2 mb-2">
            <div>
              <h3
                className="font-bold text-foreground text-base leading-tight cursor-pointer hover:text-primary transition-colors line-clamp-1"
                onClick={() => onNavigate(`my-book-detail-${story.id}`)}
              >
                {story.title}
              </h3>
              <p className="text-xs text-muted-foreground mt-0.5">{story.genre}</p>
            </div>
            <div className="relative shrink-0">
              <button
                className="w-7 h-7 rounded-lg hover:bg-muted flex items-center justify-center transition-colors"
                onClick={() => setMenuOpen(!menuOpen)}
              >
                <MoreHorizontal className="w-4 h-4 text-muted-foreground" />
              </button>
              {menuOpen && (
                <div className="absolute right-0 top-8 w-44 bg-card border border-border rounded-xl shadow-xl z-20 overflow-hidden">
                  <button
                    className="w-full flex items-center gap-2.5 px-4 py-2.5 text-sm text-foreground hover:bg-muted transition-colors"
                    onClick={() => { setMenuOpen(false); onNavigate('editor'); }}
                  >
                    <Edit3 className="w-4 h-4 text-primary" /> Écrire
                  </button>
                  <button
                    className="w-full flex items-center gap-2.5 px-4 py-2.5 text-sm text-foreground hover:bg-muted transition-colors"
                    onClick={() => { setMenuOpen(false); onNavigate('create-book'); }}
                  >
                    <FileText className="w-4 h-4 text-muted-foreground" /> Modifier les infos
                  </button>
                  <button
                    className="w-full flex items-center gap-2.5 px-4 py-2.5 text-sm text-foreground hover:bg-muted transition-colors"
                    onClick={() => { setMenuOpen(false); onNavigate('beta-submission'); }}
                  >
                    <Users className="w-4 h-4 text-muted-foreground" /> Envoyer en bêta
                  </button>
                  <div className="border-t border-border" />
                  <button
                    className="w-full flex items-center gap-2.5 px-4 py-2.5 text-sm text-destructive hover:bg-destructive/10 transition-colors"
                    onClick={() => { setMenuOpen(false); onDelete(story.id); }}
                  >
                    <Trash2 className="w-4 h-4" /> Supprimer
                  </button>
                </div>
              )}
            </div>
          </div>

          {/* Status badge */}
          <div
            className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold mb-3"
            style={{ backgroundColor: status.bg, color: status.color }}
          >
            <div className="w-1.5 h-1.5 rounded-full" style={{ backgroundColor: status.dot }} />
            {status.label}
          </div>

          {/* Stats row */}
          <div className="flex items-center gap-3 text-xs text-muted-foreground mb-3">
            <div className="flex items-center gap-1">
              <FileText className="w-3 h-3" />
              {story.chapters.length} chap.
            </div>
            <div className="flex items-center gap-1">
              <PenTool className="w-3 h-3" />
              {(story.words / 1000).toFixed(1)}k mots
            </div>
            {story.views > 0 && (
              <div className="flex items-center gap-1">
                <Eye className="w-3 h-3" />
                {(story.views / 1000).toFixed(1)}k
              </div>
            )}
            {story.betaCount > 0 && (
              <div className="flex items-center gap-1">
                <MessageSquare className="w-3 h-3" />
                {story.betaCount}
              </div>
            )}
            {story.rating && (
              <div className="flex items-center gap-1">
                <Star className="w-3 h-3 fill-yellow-400 text-yellow-400" />
                {story.rating}
              </div>
            )}
          </div>


          {/* Last edited */}
          <div className="flex items-center gap-1 text-xs text-muted-foreground mb-3">
            <Clock className="w-3 h-3" />
            {story.lastModified}
          </div>

          {/* Action buttons */}
          <div className="flex gap-2">
            <button
              onClick={() => onNavigate('editor')}
              className="flex-1 flex items-center justify-center gap-1.5 py-2 rounded-xl text-xs font-bold text-white shadow-sm hover:opacity-90 transition-opacity"
              style={{ background: 'linear-gradient(135deg, #7C5CFF, #9B80FF)' }}
            >
              <PenTool className="w-3.5 h-3.5" />
              {story.status === 'draft' ? 'Écrire' : 'Lire'}
            </button>
            <button
              onClick={() => onNavigate(story.status === 'beta' ? 'beta-feedback' : story.status === 'draft' ? 'editor' : 'royalties')}
              className="flex-1 flex items-center justify-center gap-1.5 py-2 rounded-xl text-xs font-semibold border border-border hover:bg-muted transition-colors text-foreground"
            >
              {story.status === 'beta' && <><MessageSquare className="w-3.5 h-3.5 text-primary" /> Retours</>}
              {story.status === 'draft' && <><FileText className="w-3.5 h-3.5" /> Chapitres</>}
              {story.status === 'published' && <><TrendingUp className="w-3.5 h-3.5 text-accent" /> Stats</>}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

export function WritePage({ onNavigate }: WritePageProps) {
  const [activeTab, setActiveTab] = useState('Toutes');
  const [stories, setStories] = useState(ALL_STORIES);
  const [deleteConfirm, setDeleteConfirm] = useState<number | null>(null);

  const filtered = stories.filter((s) => {
    if (activeTab === 'Toutes') return true;
    if (activeTab === 'En cours') return s.status === 'draft';
    if (activeTab === 'Bêta-test') return s.status === 'beta';
    if (activeTab === 'Publiées') return s.status === 'published';
    return true;
  });

  const handleDelete = (id: number) => {
    setDeleteConfirm(id);
  };

  const confirmDelete = () => {
    if (deleteConfirm) {
      setStories(stories.filter((s) => s.id !== deleteConfirm));
      setDeleteConfirm(null);
    }
  };

  const totalWords = stories.reduce((a, s) => a + s.words, 0);
  const totalChapters = stories.reduce((a, s) => a + s.chapters.length, 0);

  return (
    <div className="min-h-screen bg-background pb-24 md:pb-8">
      {/* Header */}
      <div className="sticky top-0 z-30 bg-background/95 border-b border-border px-4 pt-5 pb-3" style={{ backdropFilter: 'blur(12px)' }}>
        <div className="max-w-4xl mx-auto">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h1 className="text-2xl font-bold text-foreground" style={{ fontFamily: 'var(--font-family-display)' }}>
                Mes histoires
              </h1>
              <p className="text-xs text-muted-foreground mt-0.5">{stories.length} histoires · {totalChapters} chapitres · {(totalWords / 1000).toFixed(0)}k mots</p>
            </div>
            <button
              onClick={() => onNavigate('create-book')}
              className="flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm font-bold text-white shadow-lg hover:opacity-90 transition-all hover:scale-105"
              style={{ background: 'linear-gradient(135deg, #7C5CFF, #9B80FF)' }}
            >
              <Plus className="w-4 h-4" />
              Nouvelle histoire
            </button>
          </div>

          {/* Stats strip */}
          <div className="grid grid-cols-3 gap-3 mb-4">
            {[
              { label: 'Histoires', value: stories.length, icon: BookOpen, color: '#7C5CFF' },
              { label: 'Chapitres', value: totalChapters, icon: FileText, color: '#D6B25E' },
              { label: 'Mots écrits', value: `${(totalWords / 1000).toFixed(1)}k`, icon: PenTool, color: '#3FBF7F' },
            ].map(({ label, value, icon: Icon, color }) => (
              <div key={label} className="bg-card border border-border rounded-xl p-3 flex items-center gap-2.5">
                <div className="w-8 h-8 rounded-lg flex items-center justify-center shrink-0" style={{ backgroundColor: `${color}18` }}>
                  <Icon className="w-4 h-4" style={{ color }} />
                </div>
                <div>
                  <p className="text-base font-bold text-foreground">{value}</p>
                  <p className="text-[10px] text-muted-foreground">{label}</p>
                </div>
              </div>
            ))}
          </div>

          {/* Tabs */}
          <div className="flex gap-1.5 overflow-x-auto" style={{ scrollbarWidth: 'none' }}>
            {TABS.map((tab) => (
              <button
                key={tab}
                onClick={() => setActiveTab(tab)}
                className={`shrink-0 px-4 py-1.5 rounded-full text-xs font-semibold transition-all ${
                  activeTab === tab ? 'text-white shadow-md' : 'bg-muted text-muted-foreground hover:text-foreground'
                }`}
                style={activeTab === tab ? { background: 'linear-gradient(135deg, #7C5CFF, #9B80FF)' } : undefined}
              >
                {tab}
              </button>
            ))}
          </div>
        </div>
      </div>

      <div className="max-w-4xl mx-auto px-4 pt-4 space-y-3">
        {filtered.length === 0 ? (
          <div className="text-center py-20">
            <div className="w-20 h-20 mx-auto rounded-2xl bg-muted flex items-center justify-center mb-4">
              <BookOpen className="w-10 h-10 text-muted-foreground" />
            </div>
            <p className="font-bold text-lg text-foreground mb-2">Aucune histoire ici</p>
            <p className="text-sm text-muted-foreground mb-6">Commencez à écrire votre première histoire</p>
            <button
              onClick={() => onNavigate('create-book')}
              className="px-6 py-3 rounded-xl text-sm font-bold text-white shadow-lg"
              style={{ background: 'linear-gradient(135deg, #7C5CFF, #9B80FF)' }}
            >
              Créer une histoire
            </button>
          </div>
        ) : (
          filtered.map((story) => (
            <StoryCard key={story.id} story={story} onNavigate={onNavigate} onDelete={handleDelete} />
          ))
        )}

        {/* Mukeme writing assistant CTA */}
        <div
          className="rounded-2xl p-4 border border-border cursor-pointer hover:border-primary/30 transition-all"
          style={{ background: 'rgba(124,92,255,0.05)' }}
          onClick={() => onNavigate('mukeme')}
        >
          <div className="flex items-center gap-4">
            <div className="w-11 h-11 rounded-xl flex items-center justify-center shrink-0" style={{ background: 'linear-gradient(135deg, #7C5CFF, #9B80FF)' }}>
              <Sparkles className="w-5 h-5 text-white" />
            </div>
            <div className="flex-1">
              <p className="font-bold text-foreground text-sm">Mukeme — Votre assistant d'écriture IA</p>
              <p className="text-xs text-muted-foreground mt-0.5">Reformulez, améliorez le style, générez des idées</p>
            </div>
            <ChevronRight className="w-4 h-4 text-muted-foreground shrink-0" />
          </div>
        </div>

        {/* Publish CTA */}
        <div
          className="rounded-2xl p-4 border border-border cursor-pointer hover:border-accent/30 transition-all"
          style={{ background: 'rgba(214,178,94,0.05)' }}
          onClick={() => onNavigate('publication-prep')}
        >
          <div className="flex items-center gap-4">
            <div className="w-11 h-11 rounded-xl flex items-center justify-center shrink-0" style={{ background: 'linear-gradient(135deg, #D6B25E, #C49A40)' }}>
              <Upload className="w-5 h-5 text-white" />
            </div>
            <div className="flex-1">
              <p className="font-bold text-foreground text-sm">Prêt à publier ?</p>
              <p className="text-xs text-muted-foreground mt-0.5">Soumettez votre manuscrit à la communauté</p>
            </div>
            <ChevronRight className="w-4 h-4 text-muted-foreground shrink-0" />
          </div>
        </div>
      </div>

      {/* Delete confirm modal */}
      {deleteConfirm !== null && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4" style={{ background: 'rgba(0,0,0,0.5)', backdropFilter: 'blur(4px)' }}>
          <div className="bg-card border border-border rounded-2xl p-6 max-w-sm w-full shadow-2xl">
            <h3 className="font-bold text-lg text-foreground mb-2">Supprimer cette histoire ?</h3>
            <p className="text-sm text-muted-foreground mb-5">Cette action est irréversible. Tous les chapitres seront supprimés.</p>
            <div className="flex gap-3">
              <button
                onClick={() => setDeleteConfirm(null)}
                className="flex-1 py-2.5 rounded-xl border border-border text-sm font-semibold hover:bg-muted transition-colors"
              >
                Annuler
              </button>
              <button
                onClick={confirmDelete}
                className="flex-1 py-2.5 rounded-xl bg-destructive text-white text-sm font-bold hover:opacity-90 transition-opacity"
              >
                Supprimer
              </button>
            </div>
          </div>
        </div>
      )}

      <MobileNav currentPage="write" onNavigate={onNavigate} />
    </div>
  );
}
