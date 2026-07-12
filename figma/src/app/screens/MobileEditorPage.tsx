import { useState } from 'react';
import {
  ArrowLeft, Save, Sparkles, Bold, Italic, Quote, List,
  ChevronDown, ChevronLeft, ChevronRight, X, Check, Plus,
  FileText, Minus, Eye, PenTool,
} from 'lucide-react';

interface MobileEditorPageProps {
  onNavigate: (page: string) => void;
}

type Chapter = { id: number; title: string; content: string; published: boolean };

const CHAPTERS: Chapter[] = [
  { id: 1, title: 'Prologue', published: true, content: `Le monde avait changé depuis la nuit des temps. Les anciens le savaient, eux qui portaient encore les cicatrices de la Grande Rupture sur leurs âmes épuisées.\n\nClara n'avait que dix-sept ans quand elle comprit qu'elle n'était pas comme les autres.` },
  { id: 2, title: "Chapitre 1 — L'éveil", published: true, content: `La bibliothèque de l'université fermait à vingt-deux heures, mais Clara était encore là à minuit passé, enfouie sous une pile de vieux manuscrits.\n\n— Vous devriez partir, dit une voix derrière elle.\n\nElle se retourna brusquement. Un jeune homme se tenait dans l'embrasure, les bras croisés, l'air amusé.` },
  { id: 3, title: 'Chapitre 2 — La fuite', published: true, content: `Ils coururent pendant ce qui semblait des heures à travers les ruelles du vieux Montmartre, le souffle court, les pieds martelant les pavés mouillés de pluie.\n\n— Pourquoi nous suivent-ils ? souffla Clara.\n\n— Parce qu'ils savent ce que vous êtes.` },
  { id: 4, title: 'Chapitre 3 — La rencontre', published: false, content: `Il faisait nuit noire lorsque Clara franchit le seuil de la vieille bibliothèque. Les ombres dansaient sur les murs tapissés de livres anciens, créant une atmosphère à la fois mystérieuse et envoûtante.\n\nElle savait qu'elle ne devrait pas être là.` },
  { id: 5, title: 'Chapitre 4', published: false, content: '' },
];

export function MobileEditorPage({ onNavigate }: MobileEditorPageProps) {
  const [chapters, setChapters] = useState<Chapter[]>(CHAPTERS);
  const [activeChapterId, setActiveChapterId] = useState(4);
  const [showChapterList, setShowChapterList] = useState(false);
  const [showMukeme, setShowMukeme] = useState(false);
  const [readMode, setReadMode] = useState(false);
  const [saved, setSaved] = useState(true);
  const [saving, setSaving] = useState(false);
  const [addingChapter, setAddingChapter] = useState(false);
  const [newTitle, setNewTitle] = useState('');

  const activeIndex = chapters.findIndex((c) => c.id === activeChapterId);
  const activeChapter = chapters[activeIndex];
  const prevChapter = activeIndex > 0 ? chapters[activeIndex - 1] : null;
  const nextChapter = activeIndex < chapters.length - 1 ? chapters[activeIndex + 1] : null;
  const wordCount = (activeChapter?.content ?? '').trim().split(/\s+/).filter(Boolean).length;

  const updateContent = (val: string) => {
    setChapters((prev) => prev.map((c) => (c.id === activeChapterId ? { ...c, content: val } : c)));
    setSaved(false);
  };

  const handleSave = () => {
    setSaving(true);
    setTimeout(() => { setSaving(false); setSaved(true); }, 700);
  };

  const goToChapter = (id: number) => {
    if (!saved) handleSave();
    setActiveChapterId(id);
    setShowChapterList(false);
    setReadMode(false);
  };

  const addChapter = () => {
    if (!newTitle.trim()) return;
    const ch: Chapter = { id: Date.now(), title: newTitle, content: '', published: false };
    setChapters([...chapters, ch]);
    setNewTitle('');
    setAddingChapter(false);
    goToChapter(ch.id);
  };

  return (
    <div className="h-screen bg-background flex flex-col overflow-hidden">

      {/* Top bar */}
      <div className="flex items-center px-4 pt-5 pb-3 bg-card border-b border-border gap-3 shrink-0">
        <button onClick={() => onNavigate('write')} className="w-9 h-9 rounded-xl hover:bg-muted flex items-center justify-center">
          <ArrowLeft className="w-5 h-5 text-muted-foreground" />
        </button>

        {/* Chapter selector */}
        <button
          onClick={() => setShowChapterList(true)}
          className="flex-1 flex items-center justify-center gap-1.5 min-w-0"
        >
          <div className="min-w-0 text-center">
            <p className="text-sm font-bold text-foreground truncate">{activeChapter?.title}</p>
            <p className="text-xs text-muted-foreground">
              {activeIndex + 1}/{chapters.length} · {wordCount} mots
              {activeChapter?.published && ' · Publié'}
            </p>
          </div>
          <ChevronDown className="w-4 h-4 text-muted-foreground shrink-0" />
        </button>

        <div className="flex items-center gap-1.5">
          {/* Read/Write toggle */}
          <button
            onClick={() => setReadMode(!readMode)}
            className="w-9 h-9 rounded-xl hover:bg-muted flex items-center justify-center transition-colors"
          >
            {readMode
              ? <PenTool className="w-4 h-4 text-primary" />
              : <Eye className="w-4 h-4 text-muted-foreground" />
            }
          </button>

          {/* Save */}
          {!readMode && (
            <button
              onClick={handleSave}
              className="w-9 h-9 rounded-xl flex items-center justify-center"
              style={{ background: saved ? 'rgba(63,191,127,0.12)' : 'linear-gradient(135deg, #7C5CFF, #9B80FF)' }}
            >
              {saving
                ? <div className="w-4 h-4 border-2 border-current border-t-transparent rounded-full animate-spin" style={{ color: '#3FBF7F' }} />
                : saved
                  ? <Check className="w-4 h-4" style={{ color: '#3FBF7F' }} />
                  : <Save className="w-4 h-4 text-white" />
              }
            </button>
          )}
        </div>
      </div>

      {/* Reading mode banner */}
      {readMode && (
        <div className="flex items-center justify-between px-4 py-2 shrink-0" style={{ background: 'rgba(63,191,127,0.08)' }}>
          <div className="flex items-center gap-2">
            <Eye className="w-3.5 h-3.5" style={{ color: '#3FBF7F' }} />
            <span className="text-xs font-semibold" style={{ color: '#3FBF7F' }}>Mode lecture</span>
          </div>
          <button onClick={() => setReadMode(false)} className="text-xs font-semibold text-primary">Écrire</button>
        </div>
      )}

      {/* Writing / Reading area */}
      <div className="flex-1 overflow-y-auto px-5 py-5">
        {readMode ? (
          <div>
            <h2 className="text-xl font-bold text-foreground mb-5" style={{ fontFamily: 'var(--font-family-display)' }}>
              {activeChapter?.title}
            </h2>
            <div
              className="text-foreground whitespace-pre-wrap leading-relaxed"
              style={{ fontSize: '16px', lineHeight: '1.9', fontFamily: "'Georgia', serif" }}
            >
              {activeChapter?.content || <span className="text-muted-foreground italic">Ce chapitre est vide.</span>}
            </div>
          </div>
        ) : (
          <textarea
            value={activeChapter?.content ?? ''}
            onChange={(e) => updateContent(e.target.value)}
            className="w-full h-full min-h-full bg-transparent border-none focus:outline-none resize-none text-foreground placeholder:text-muted-foreground/40"
            placeholder="Commencez à écrire..."
            style={{ fontSize: '16px', lineHeight: '1.9', fontFamily: "'Georgia', serif" }}
          />
        )}

        {/* Prev / Next chapter navigation */}
        <div className="flex items-center justify-between mt-8 pt-6 border-t border-border">
          {prevChapter ? (
            <button
              onClick={() => goToChapter(prevChapter.id)}
              className="flex items-center gap-2 px-3 py-2.5 rounded-xl border border-border hover:bg-muted transition-colors group max-w-[45%]"
            >
              <ChevronLeft className="w-4 h-4 text-muted-foreground shrink-0" />
              <div className="text-left min-w-0">
                <p className="text-[10px] text-muted-foreground">Précédent</p>
                <p className="text-xs font-semibold text-foreground truncate">{prevChapter.title}</p>
              </div>
            </button>
          ) : <div />}

          {nextChapter ? (
            <button
              onClick={() => goToChapter(nextChapter.id)}
              className="flex items-center gap-2 px-3 py-2.5 rounded-xl border border-border hover:bg-muted transition-colors group max-w-[45%] ml-auto"
            >
              <div className="text-right min-w-0">
                <p className="text-[10px] text-muted-foreground">Suivant</p>
                <p className="text-xs font-semibold text-foreground truncate">{nextChapter.title}</p>
              </div>
              <ChevronRight className="w-4 h-4 text-muted-foreground shrink-0" />
            </button>
          ) : (
            <button
              onClick={() => setAddingChapter(true)}
              className="flex items-center gap-1.5 px-3 py-2.5 rounded-xl border border-dashed border-border text-xs font-semibold text-muted-foreground hover:border-primary/50 hover:text-primary transition-colors ml-auto"
            >
              <Plus className="w-4 h-4" /> Nouveau chapitre
            </button>
          )}
        </div>
      </div>

      {/* Mukeme panel */}
      {showMukeme && (
        <div className="bg-card border-t border-border p-4 shrink-0">
          <div className="flex items-center justify-between mb-3">
            <div className="flex items-center gap-2">
              <div className="w-7 h-7 rounded-lg flex items-center justify-center" style={{ background: 'linear-gradient(135deg, #7C5CFF, #9B80FF)' }}>
                <Sparkles className="w-3.5 h-3.5 text-white" />
              </div>
              <span className="font-bold text-sm text-foreground">Mukeme</span>
            </div>
            <button onClick={() => setShowMukeme(false)}><X className="w-5 h-5 text-muted-foreground" /></button>
          </div>
          <div className="grid grid-cols-2 gap-2">
            {['Reformuler', 'Améliorer le style', 'Développer', 'Corriger'].map((action) => (
              <button key={action} className="py-2.5 rounded-xl text-xs font-semibold border border-border hover:bg-muted transition-colors">
                {action}
              </button>
            ))}
          </div>
        </div>
      )}

      {/* Bottom toolbar (write mode only) */}
      {!readMode && !showMukeme && (
        <div className="bg-card border-t border-border px-4 py-3 flex items-center justify-between shrink-0">
          <div className="flex items-center gap-1">
            {[
              { icon: Bold, label: 'Gras' },
              { icon: Italic, label: 'Italique' },
              { icon: Quote, label: 'Citation' },
              { icon: List, label: 'Liste' },
              { icon: Minus, label: 'Séparateur' },
            ].map(({ icon: Icon, label }) => (
              <button key={label} title={label} className="w-10 h-10 rounded-xl hover:bg-muted flex items-center justify-center transition-colors text-muted-foreground">
                <Icon className="w-5 h-5" />
              </button>
            ))}
          </div>
          <button
            onClick={() => setShowMukeme(true)}
            className="flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-bold"
            style={{ background: 'rgba(124,92,255,0.12)', color: '#7C5CFF' }}
          >
            <Sparkles className="w-4 h-4" /> Mukeme
          </button>
        </div>
      )}

      {/* Chapter list bottom sheet */}
      {showChapterList && (
        <div className="fixed inset-0 z-50 flex flex-col justify-end" style={{ background: 'rgba(0,0,0,0.5)', backdropFilter: 'blur(4px)' }}>
          <div className="bg-card rounded-t-3xl max-h-[80vh] flex flex-col">
            <div className="flex items-center justify-between px-5 pt-5 pb-3 border-b border-border">
              <div>
                <h3 className="font-bold text-base text-foreground">Tous les chapitres</h3>
                <p className="text-xs text-muted-foreground">La Nuit Rouge · {chapters.length} chapitres</p>
              </div>
              <div className="flex gap-2">
                <button onClick={() => setAddingChapter(true)} className="w-9 h-9 rounded-xl hover:bg-muted flex items-center justify-center" style={{ color: '#7C5CFF' }}>
                  <Plus className="w-5 h-5" />
                </button>
                <button onClick={() => setShowChapterList(false)} className="w-9 h-9 rounded-xl hover:bg-muted flex items-center justify-center">
                  <X className="w-5 h-5 text-muted-foreground" />
                </button>
              </div>
            </div>

            {addingChapter && (
              <div className="px-5 py-3 border-b border-border">
                <input
                  autoFocus
                  value={newTitle}
                  onChange={(e) => setNewTitle(e.target.value)}
                  onKeyDown={(e) => { if (e.key === 'Enter') addChapter(); if (e.key === 'Escape') setAddingChapter(false); }}
                  placeholder="Titre du chapitre..."
                  className="w-full px-4 py-2.5 rounded-xl bg-muted border border-border text-sm focus:outline-none focus:border-primary/50 text-foreground placeholder:text-muted-foreground"
                />
                <div className="flex gap-2 mt-2">
                  <button onClick={addChapter} className="flex-1 py-2 rounded-xl text-sm font-bold text-white" style={{ background: 'linear-gradient(135deg, #7C5CFF, #9B80FF)' }}>Ajouter</button>
                  <button onClick={() => setAddingChapter(false)} className="flex-1 py-2 rounded-xl text-sm bg-muted text-muted-foreground">Annuler</button>
                </div>
              </div>
            )}

            <div className="overflow-y-auto flex-1 p-3 space-y-1">
              {chapters.map((ch, idx) => {
                const chWords = ch.content.trim().split(/\s+/).filter(Boolean).length;
                const isActive = ch.id === activeChapterId;
                return (
                  <div
                    key={ch.id}
                    onClick={() => goToChapter(ch.id)}
                    className={`flex items-center gap-3 px-4 py-3 rounded-2xl cursor-pointer transition-all ${
                      isActive ? 'text-white' : 'hover:bg-muted text-foreground'
                    }`}
                    style={isActive ? { background: 'linear-gradient(135deg, #7C5CFF, #9B80FF)' } : undefined}
                  >
                    <span className={`text-xs font-bold w-5 text-center shrink-0 ${isActive ? 'text-white/60' : 'text-muted-foreground'}`}>
                      {idx + 1}
                    </span>
                    <FileText className={`w-4 h-4 shrink-0 ${isActive ? 'text-white/70' : 'text-muted-foreground'}`} />
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-semibold truncate">{ch.title}</p>
                      <p className={`text-xs flex items-center gap-2 ${isActive ? 'text-white/60' : 'text-muted-foreground'}`}>
                        <span>{chWords > 0 ? `${chWords} mots` : 'Vide'}</span>
                        {ch.published
                          ? <span className={isActive ? 'text-green-300' : 'text-green-500'}>● Publié</span>
                          : <span>● Brouillon</span>
                        }
                      </p>
                    </div>
                    {isActive && <Check className="w-4 h-4 text-white shrink-0" />}
                  </div>
                );
              })}
            </div>
            <div className="h-6" />
          </div>
        </div>
      )}
    </div>
  );
}
