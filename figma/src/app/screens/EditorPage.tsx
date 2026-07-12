import { useState } from 'react';
import {
  ArrowLeft, Save, Eye, Sparkles, Plus, FileText, MoreVertical,
  Bold, Italic, Underline, Quote, List, Minus,
  Check, Trash2, GripVertical, PenTool, Settings,
  MessageSquare, Upload, TrendingUp, BookOpen, Smartphone,
  ChevronLeft, ChevronRight, EyeOff,
} from 'lucide-react';

interface EditorPageProps {
  onNavigate: (page: string) => void;
}

type Chapter = {
  id: number;
  title: string;
  content: string;
  published: boolean;
};

const INITIAL_CHAPTERS: Chapter[] = [
  {
    id: 1,
    title: 'Prologue',
    published: true,
    content: `Le monde avait changé depuis la nuit des temps. Les anciens le savaient, eux qui portaient encore les cicatrices de la Grande Rupture sur leurs âmes épuisées.

Clara n'avait que dix-sept ans quand elle comprit qu'elle n'était pas comme les autres. Ce n'était pas une révélation soudaine, mais une accumulation de petits signes, de regards qui s'attardent, de portes qui s'ouvrent avant qu'elle les touche.

Ce soir-là, sous un ciel sans étoiles, tout bascula.`,
  },
  {
    id: 2,
    title: "Chapitre 1 — L'éveil",
    published: true,
    content: `La bibliothèque de l'université fermait à vingt-deux heures, mais Clara était encore là à minuit passé, enfouie sous une pile de vieux manuscrits que le professeur Delacroix lui avait confiés.

— Vous devriez partir, dit une voix derrière elle.

Elle se retourna brusquement. Un jeune homme d'une vingtaine d'années se tenait dans l'embrasure de la porte, les bras croisés, l'air amusé. Elle ne l'avait jamais vu ici.

— Je travaille, répondit-elle froidement.

— Je sais. C'est justement le problème.

Il s'avança de quelques pas, et Clara remarqua alors ses yeux — d'un bleu presque violet, comme deux éclats de ciel nocturne. Elle ne put s'empêcher de frissonner.

— Qui êtes-vous ? demanda-t-elle.

Il sourit. Ce sourire qu'elle apprendrait à détester — et à adorer.

— Quelqu'un qui vous cherchait depuis longtemps.`,
  },
  {
    id: 3,
    title: 'Chapitre 2 — La fuite',
    published: true,
    content: `Ils coururent pendant ce qui semblait des heures à travers les ruelles du vieux Montmartre, le souffle court, les pieds martelant les pavés mouillés de pluie.

Clara n'avait toujours pas compris ce qui se passait. Vingt minutes plus tôt, elle était dans sa bibliothèque. Maintenant, elle fuyait avec un inconnu aux yeux violets, et deux hommes en manteaux noirs les pourchassaient dans le labyrinthe des rues.

— Pourquoi nous suivent-ils ? souffla-t-elle entre deux foulées.

— Parce qu'ils savent ce que vous êtes.

— Et qu'est-ce que je suis ?

Il s'arrêta brusquement devant une porte basse, plaqua sa main sur le bois vermoulu. La serrure cliqua toute seule.

— Vous êtes la dernière Gardienne.`,
  },
  {
    id: 4,
    title: 'Chapitre 3 — La rencontre',
    published: false,
    content: `Il faisait nuit noire lorsque Clara franchit le seuil de la vieille bibliothèque. Les ombres dansaient sur les murs tapissés de livres anciens, créant une atmosphère à la fois mystérieuse et envoûtante.

Elle savait qu'elle ne devrait pas être là. Les rumeurs parlaient d'esprits hantant ces lieux depuis des siècles, gardiens éternels d'un savoir oublié. Mais Clara n'avait pas le choix. Quelque part dans ces rayonnages se cachait la clé de son passé.

Ses pas résonnaient sur le parquet grinçant alors qu'elle s'avançait entre les étagères immenses, la lumière de sa lampe projetant des ombres mouvantes sur les reliures dorées.

Au détour d'une allée, elle s'arrêta. Un livre avait glissé à terre, ouvert sur une page qu'elle n'avait pas touchée. Les caractères semblaient briller d'une lumière propre, indépendante de sa lampe.

Clara se pencha. Les mots étaient écrits dans une langue qu'elle ne reconnaissait pas, et pourtant... elle comprenait.`,
  },
  {
    id: 5,
    title: 'Chapitre 4',
    published: false,
    content: '',
  },
];

export function EditorPage({ onNavigate }: EditorPageProps) {
  const [chapters, setChapters] = useState<Chapter[]>(INITIAL_CHAPTERS);
  const [activeChapterId, setActiveChapterId] = useState(4);
  const [saved, setSaved] = useState(true);
  const [saving, setSaving] = useState(false);
  const [chapterMenu, setChapterMenu] = useState<number | null>(null);
  const [addingChapter, setAddingChapter] = useState(false);
  const [newChapterTitle, setNewChapterTitle] = useState('');
  const [showMukeme, setShowMukeme] = useState(false);
  const [readMode, setReadMode] = useState(false);

  const activeIndex = chapters.findIndex((c) => c.id === activeChapterId);
  const activeChapter = chapters[activeIndex];
  const prevChapter = activeIndex > 0 ? chapters[activeIndex - 1] : null;
  const nextChapter = activeIndex < chapters.length - 1 ? chapters[activeIndex + 1] : null;

  const wordCount = (activeChapter?.content ?? '').trim().split(/\s+/).filter(Boolean).length;
  const readTime = Math.max(1, Math.round(wordCount / 200));

  const updateContent = (val: string) => {
    setChapters((prev) =>
      prev.map((c) => (c.id === activeChapterId ? { ...c, content: val } : c))
    );
    setSaved(false);
  };

  const updateTitle = (val: string) => {
    setChapters((prev) =>
      prev.map((c) => (c.id === activeChapterId ? { ...c, title: val } : c))
    );
    setSaved(false);
  };

  const handleSave = () => {
    setSaving(true);
    setTimeout(() => { setSaving(false); setSaved(true); }, 700);
  };

  const goToChapter = (id: number) => {
    if (!saved) handleSave();
    setActiveChapterId(id);
    setReadMode(false);
  };

  const addChapter = () => {
    if (!newChapterTitle.trim()) return;
    const newCh: Chapter = { id: Date.now(), title: newChapterTitle, content: '', published: false };
    setChapters([...chapters, newCh]);
    setNewChapterTitle('');
    setAddingChapter(false);
    setActiveChapterId(newCh.id);
  };

  const deleteChapter = (id: number) => {
    const remaining = chapters.filter((c) => c.id !== id);
    setChapters(remaining);
    setChapterMenu(null);
    if (activeChapterId === id && remaining.length > 0) {
      setActiveChapterId(remaining[Math.min(activeIndex, remaining.length - 1)].id);
    }
  };

  const togglePublish = (id: number) => {
    setChapters((prev) => prev.map((c) => (c.id === id ? { ...c, published: !c.published } : c)));
    setChapterMenu(null);
  };

  return (
    <div className="h-screen bg-background flex overflow-hidden">

      {/* ═══ SIDEBAR 1 — Book nav ═══ */}
      <aside className="hidden md:flex w-56 bg-card border-r border-border flex-col shrink-0">
        <div className="p-4 border-b border-border">
          <button
            onClick={() => onNavigate('write')}
            className="flex items-center gap-1.5 text-xs text-muted-foreground hover:text-foreground mb-3 transition-colors"
          >
            <ArrowLeft className="w-3.5 h-3.5" /> Mes histoires
          </button>
          <div className="flex items-center gap-3">
            <div className="w-10 h-14 rounded-lg bg-gradient-to-br from-violet-600 via-purple-700 to-indigo-800 shrink-0 shadow-md" />
            <div className="min-w-0">
              <p className="font-bold text-sm text-foreground truncate">La Nuit Rouge</p>
              <p className="text-xs text-muted-foreground">Fantasy · {chapters.length} chap.</p>
            </div>
          </div>
        </div>

        <nav className="flex-1 p-3 space-y-1">
          {[
            { icon: BookOpen, label: "Vue d'ensemble", page: 'write', active: false },
            { icon: PenTool, label: 'Éditeur', page: 'editor', active: true },
            { icon: MessageSquare, label: 'Retours bêta', page: 'beta-feedback', active: false },
            { icon: Upload, label: 'Bêta-test', page: 'beta-submission', active: false },
            { icon: TrendingUp, label: 'Royalties', page: 'royalties', active: false },
            { icon: Settings, label: 'Paramètres', page: 'create-book', active: false },
          ].map(({ icon: Icon, label, page, active }) => (
            <button
              key={label}
              onClick={() => onNavigate(page)}
              className={`w-full flex items-center gap-2.5 px-3 py-2 rounded-xl text-sm transition-colors ${
                active ? 'text-white font-semibold' : 'text-muted-foreground hover:bg-muted hover:text-foreground'
              }`}
              style={active ? { background: 'linear-gradient(135deg, #7C5CFF, #9B80FF)' } : undefined}
            >
              <Icon className="w-4 h-4 shrink-0" />
              <span className="truncate">{label}</span>
            </button>
          ))}
        </nav>

        <div className="p-3 border-t border-border">
          <button
            onClick={() => onNavigate('mobile-editor')}
            className="w-full flex items-center gap-2 px-3 py-2 rounded-xl text-xs text-muted-foreground hover:bg-muted transition-colors"
          >
            <Smartphone className="w-4 h-4" /> Vue mobile
          </button>
        </div>
      </aside>

      {/* ═══ SIDEBAR 2 — Chapters ═══ */}
      <aside className="hidden md:flex w-60 bg-background border-r border-border flex-col shrink-0">
        <div className="p-4 border-b border-border flex items-center justify-between">
          <div>
            <h3 className="font-bold text-sm text-foreground">Chapitres</h3>
            <p className="text-xs text-muted-foreground">{chapters.length} chapitres · {chapters.filter(c => c.content).reduce((a, c) => a + c.content.trim().split(/\s+/).filter(Boolean).length, 0)} mots</p>
          </div>
          <button
            onClick={() => setAddingChapter(true)}
            className="w-8 h-8 rounded-xl flex items-center justify-center hover:bg-muted transition-colors"
            style={{ color: '#7C5CFF' }}
          >
            <Plus className="w-4 h-4" />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto p-2 space-y-0.5">
          {chapters.map((ch, idx) => {
            const chWords = ch.content.trim().split(/\s+/).filter(Boolean).length;
            const isActive = ch.id === activeChapterId;
            return (
              <div key={ch.id} className="relative group">
                <div
                  onClick={() => goToChapter(ch.id)}
                  className={`w-full flex items-center gap-2 px-3 py-2.5 rounded-xl cursor-pointer transition-all ${
                    isActive ? 'text-white' : 'text-foreground hover:bg-muted'
                  }`}
                  style={isActive ? { background: 'linear-gradient(135deg, #7C5CFF, #9B80FF)' } : undefined}
                >
                  <span className={`text-[10px] font-bold w-4 text-center shrink-0 ${isActive ? 'text-white/60' : 'text-muted-foreground'}`}>
                    {idx + 1}
                  </span>
                  <div className="flex-1 min-w-0">
                    <p className="text-xs font-semibold truncate">{ch.title}</p>
                    <div className={`flex items-center gap-2 text-[10px] ${isActive ? 'text-white/60' : 'text-muted-foreground'}`}>
                      <span>{chWords > 0 ? `${chWords} mots` : 'Vide'}</span>
                      {ch.published
                        ? <span className={isActive ? 'text-green-300' : 'text-success'}>● Publié</span>
                        : <span>● Brouillon</span>
                      }
                    </div>
                  </div>
                  <button
                    onClick={(e) => { e.stopPropagation(); setChapterMenu(chapterMenu === ch.id ? null : ch.id); }}
                    className={`w-5 h-5 rounded flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity shrink-0 ${
                      isActive ? 'hover:bg-white/20' : 'hover:bg-muted'
                    }`}
                  >
                    <MoreVertical className="w-3 h-3" />
                  </button>
                </div>

                {chapterMenu === ch.id && (
                  <div className="absolute right-2 top-full mt-1 w-44 bg-card border border-border rounded-xl shadow-xl z-20 overflow-hidden">
                    <button className="w-full flex items-center gap-2 px-3 py-2.5 text-xs text-foreground hover:bg-muted" onClick={() => { goToChapter(ch.id); setReadMode(false); setChapterMenu(null); }}>
                      <PenTool className="w-3.5 h-3.5 text-primary" /> Écrire
                    </button>
                    <button className="w-full flex items-center gap-2 px-3 py-2.5 text-xs text-foreground hover:bg-muted" onClick={() => { goToChapter(ch.id); setReadMode(true); setChapterMenu(null); }}>
                      <Eye className="w-3.5 h-3.5 text-muted-foreground" /> Lire
                    </button>
                    <button className="w-full flex items-center gap-2 px-3 py-2.5 text-xs text-foreground hover:bg-muted" onClick={() => togglePublish(ch.id)}>
                      {ch.published
                        ? <><EyeOff className="w-3.5 h-3.5 text-muted-foreground" /> Dépublier</>
                        : <><Check className="w-3.5 h-3.5 text-success" /> Publier</>
                      }
                    </button>
                    <div className="border-t border-border" />
                    <button className="w-full flex items-center gap-2 px-3 py-2.5 text-xs text-destructive hover:bg-destructive/10" onClick={() => deleteChapter(ch.id)}>
                      <Trash2 className="w-3.5 h-3.5" /> Supprimer
                    </button>
                  </div>
                )}
              </div>
            );
          })}

          {addingChapter && (
            <div className="px-2 py-1">
              <input
                autoFocus
                type="text"
                value={newChapterTitle}
                onChange={(e) => setNewChapterTitle(e.target.value)}
                onKeyDown={(e) => { if (e.key === 'Enter') addChapter(); if (e.key === 'Escape') setAddingChapter(false); }}
                placeholder="Titre du chapitre..."
                className="w-full px-3 py-2 rounded-xl bg-card border border-primary/50 text-xs text-foreground placeholder:text-muted-foreground focus:outline-none"
              />
              <div className="flex gap-1 mt-1">
                <button onClick={addChapter} className="flex-1 py-1.5 rounded-lg text-white text-xs font-semibold" style={{ background: 'linear-gradient(135deg, #7C5CFF, #9B80FF)' }}>Ajouter</button>
                <button onClick={() => setAddingChapter(false)} className="flex-1 py-1.5 rounded-lg bg-muted text-muted-foreground text-xs">Annuler</button>
              </div>
            </div>
          )}
        </div>

        {!addingChapter && (
          <div className="p-3 border-t border-border">
            <button
              onClick={() => setAddingChapter(true)}
              className="w-full flex items-center justify-center gap-2 py-2.5 rounded-xl border border-dashed border-border text-xs font-semibold text-muted-foreground hover:border-primary/50 hover:text-primary transition-colors"
            >
              <Plus className="w-3.5 h-3.5" /> Nouveau chapitre
            </button>
          </div>
        )}
      </aside>

      {/* ═══ MAIN EDITOR ═══ */}
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">

        {/* Toolbar */}
        <div className="bg-card border-b border-border px-4 py-2.5 flex items-center justify-between gap-3 shrink-0">
          {/* Mobile back */}
          <button onClick={() => onNavigate('write')} className="md:hidden flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground">
            <ArrowLeft className="w-4 h-4" />
          </button>

          {/* Formatting (hidden in read mode) */}
          {!readMode ? (
            <div className="flex items-center gap-0.5 overflow-x-auto" style={{ scrollbarWidth: 'none' }}>
              {[
                { icon: Bold, label: 'Gras' },
                { icon: Italic, label: 'Italique' },
                { icon: Underline, label: 'Souligner' },
              ].map(({ icon: Icon, label }) => (
                <button key={label} title={label} className="w-8 h-8 rounded-lg hover:bg-muted flex items-center justify-center transition-colors text-muted-foreground hover:text-foreground">
                  <Icon className="w-4 h-4" />
                </button>
              ))}
              <div className="w-px h-5 bg-border mx-1" />
              {[
                { icon: Quote, label: 'Citation' },
                { icon: List, label: 'Liste' },
                { icon: Minus, label: 'Séparateur' },
              ].map(({ icon: Icon, label }) => (
                <button key={label} title={label} className="w-8 h-8 rounded-lg hover:bg-muted flex items-center justify-center transition-colors text-muted-foreground hover:text-foreground">
                  <Icon className="w-4 h-4" />
                </button>
              ))}
            </div>
          ) : (
            <div className="flex items-center gap-2 px-3 py-1 rounded-xl" style={{ background: 'rgba(63,191,127,0.1)' }}>
              <Eye className="w-3.5 h-3.5" style={{ color: '#3FBF7F' }} />
              <span className="text-xs font-semibold" style={{ color: '#3FBF7F' }}>Mode lecture</span>
            </div>
          )}

          {/* Right actions */}
          <div className="flex items-center gap-2 shrink-0">
            <button
              onClick={() => setReadMode(!readMode)}
              className="hidden sm:flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-medium border border-border hover:bg-muted transition-colors text-muted-foreground"
            >
              {readMode ? <PenTool className="w-3.5 h-3.5" /> : <Eye className="w-3.5 h-3.5" />}
              {readMode ? 'Écrire' : 'Lire'}
            </button>
            {!readMode && (
              <button
                onClick={() => setShowMukeme(!showMukeme)}
                className="hidden sm:flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-bold transition-all hover:opacity-90"
                style={{ background: 'rgba(124,92,255,0.12)', color: '#7C5CFF' }}
              >
                <Sparkles className="w-3.5 h-3.5" /> Mukeme
              </button>
            )}
            {!readMode && (
              <button
                onClick={handleSave}
                className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-bold transition-all hover:opacity-90"
                style={{ background: saved ? 'rgba(63,191,127,0.12)' : 'linear-gradient(135deg, #7C5CFF, #9B80FF)', color: saved ? '#3FBF7F' : 'white' }}
              >
                {saving ? <div className="w-3.5 h-3.5 border-2 border-current border-t-transparent rounded-full animate-spin" /> : saved ? <Check className="w-3.5 h-3.5" /> : <Save className="w-3.5 h-3.5" />}
                {saving ? 'Sauvegarde...' : saved ? 'Sauvegardé' : 'Enregistrer'}
              </button>
            )}
          </div>
        </div>

        {/* Mukeme panel */}
        {showMukeme && !readMode && (
          <div className="bg-card border-b border-border px-6 py-3 flex items-center gap-3 shrink-0">
            <div className="w-8 h-8 rounded-xl flex items-center justify-center shrink-0" style={{ background: 'linear-gradient(135deg, #7C5CFF, #9B80FF)' }}>
              <Sparkles className="w-4 h-4 text-white" />
            </div>
            <p className="text-xs text-muted-foreground flex-1">Sélectionnez du texte puis demandez à Mukeme.</p>
            {['Reformuler', 'Améliorer le style', 'Développer', 'Résumer'].map((action) => (
              <button key={action} className="shrink-0 px-3 py-1.5 rounded-xl text-xs font-semibold border border-border hover:bg-muted transition-colors">
                {action}
              </button>
            ))}
            <button onClick={() => setShowMukeme(false)} className="text-muted-foreground hover:text-foreground text-xl leading-none">×</button>
          </div>
        )}

        {/* Content */}
        <div className="flex-1 overflow-y-auto">
          <div className="max-w-3xl mx-auto px-6 py-8">

            {/* Chapter nav breadcrumb */}
            <div className="flex items-center gap-2 mb-6 text-xs text-muted-foreground">
              <span>La Nuit Rouge</span>
              <ChevronRight className="w-3 h-3" />
              <span className="text-foreground font-medium">
                {activeIndex + 1}. {activeChapter?.title}
              </span>
            </div>

            {/* Chapter title */}
            {readMode ? (
              <h2
                className="text-2xl md:text-3xl font-bold text-foreground mb-6"
                style={{ fontFamily: 'var(--font-family-display)' }}
              >
                {activeChapter?.title}
              </h2>
            ) : (
              <input
                type="text"
                value={activeChapter?.title ?? ''}
                onChange={(e) => updateTitle(e.target.value)}
                className="w-full text-2xl md:text-3xl font-bold text-foreground bg-transparent border-none focus:outline-none mb-6 placeholder:text-muted-foreground/40"
                style={{ fontFamily: 'var(--font-family-display)' }}
                placeholder="Titre du chapitre..."
              />
            )}

            {/* Status strip */}
            <div className="flex items-center gap-4 mb-8 pb-4 border-b border-border">
              {activeChapter?.published
                ? <span className="text-xs font-semibold" style={{ color: '#3FBF7F' }}>● Publié</span>
                : <span className="text-xs text-muted-foreground">● Brouillon</span>
              }
              <span className="text-xs text-muted-foreground">{wordCount} mots · ~{readTime} min lecture</span>
              {!readMode && !activeChapter?.published && (
                <button
                  onClick={() => togglePublish(activeChapterId)}
                  className="ml-auto px-3 py-1 rounded-lg text-xs font-semibold border border-border hover:bg-muted transition-colors"
                >
                  Publier ce chapitre
                </button>
              )}
              {!readMode && activeChapter?.published && (
                <button
                  onClick={() => togglePublish(activeChapterId)}
                  className="ml-auto px-3 py-1 rounded-lg text-xs font-semibold border border-border hover:bg-muted transition-colors text-muted-foreground"
                >
                  Dépublier
                </button>
              )}
            </div>

            {/* Writing / Reading area */}
            {readMode ? (
              <div
                className="text-foreground whitespace-pre-wrap leading-relaxed min-h-[40vh]"
                style={{ fontSize: '17px', lineHeight: '1.9', fontFamily: "'Georgia', serif" }}
              >
                {activeChapter?.content || <span className="text-muted-foreground/50 italic">Ce chapitre est vide.</span>}
              </div>
            ) : (
              <textarea
                value={activeChapter?.content ?? ''}
                onChange={(e) => updateContent(e.target.value)}
                className="w-full min-h-[50vh] bg-transparent border-none focus:outline-none resize-none text-foreground placeholder:text-muted-foreground/40"
                placeholder="Commencez à écrire ce chapitre..."
                style={{ fontSize: '17px', lineHeight: '1.9', fontFamily: "'Georgia', serif" }}
              />
            )}

            {/* Chapter navigation arrows */}
            <div className="flex items-center justify-between mt-12 pt-6 border-t border-border">
              {prevChapter ? (
                <button
                  onClick={() => goToChapter(prevChapter.id)}
                  className="flex items-center gap-2 px-4 py-3 rounded-xl border border-border hover:bg-muted transition-colors group max-w-[45%]"
                >
                  <ChevronLeft className="w-4 h-4 text-muted-foreground shrink-0 group-hover:text-foreground" />
                  <div className="text-left min-w-0">
                    <p className="text-[10px] text-muted-foreground uppercase tracking-wide">Chapitre précédent</p>
                    <p className="text-sm font-semibold text-foreground truncate">{prevChapter.title}</p>
                  </div>
                </button>
              ) : <div />}

              {nextChapter ? (
                <button
                  onClick={() => goToChapter(nextChapter.id)}
                  className="flex items-center gap-2 px-4 py-3 rounded-xl border border-border hover:bg-muted transition-colors group max-w-[45%] ml-auto"
                >
                  <div className="text-right min-w-0">
                    <p className="text-[10px] text-muted-foreground uppercase tracking-wide">Chapitre suivant</p>
                    <p className="text-sm font-semibold text-foreground truncate">{nextChapter.title}</p>
                  </div>
                  <ChevronRight className="w-4 h-4 text-muted-foreground shrink-0 group-hover:text-foreground" />
                </button>
              ) : (
                <button
                  onClick={() => setAddingChapter(true)}
                  className="flex items-center gap-2 px-4 py-3 rounded-xl border border-dashed border-border hover:border-primary/50 hover:text-primary transition-colors text-muted-foreground ml-auto"
                >
                  <Plus className="w-4 h-4" />
                  <span className="text-sm font-semibold">Nouveau chapitre</span>
                </button>
              )}
            </div>
          </div>
        </div>

        {/* Bottom stats bar */}
        <div className="bg-card border-t border-border px-4 py-2 flex items-center gap-4 text-xs text-muted-foreground shrink-0">
          <span><strong className="text-foreground">{wordCount}</strong> mots</span>
          <span><strong className="text-foreground">{activeChapter?.content.length ?? 0}</strong> car.</span>
          <span>~<strong className="text-foreground">{readTime}</strong> min lecture</span>
          <span className="hidden sm:block">
            Chapitre <strong className="text-foreground">{activeIndex + 1}</strong>/{chapters.length}
          </span>
          <span className="ml-auto">
            {saved
              ? <span style={{ color: '#3FBF7F' }}>● Sauvegardé</span>
              : <span style={{ color: '#D6B25E' }}>● Non sauvegardé</span>
            }
          </span>
        </div>
      </div>
    </div>
  );
}
