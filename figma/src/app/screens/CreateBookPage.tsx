import { useState } from 'react';
import { ArrowLeft, Camera, Check, Lock, Globe, Users } from 'lucide-react';

interface CreateBookPageProps {
  onNavigate: (page: string) => void;
}

const COVER_PRESETS = [
  { id: 1, gradient: 'from-violet-600 via-purple-700 to-indigo-800' },
  { id: 2, gradient: 'from-rose-500 via-red-600 to-orange-700' },
  { id: 3, gradient: 'from-blue-600 via-indigo-700 to-slate-800' },
  { id: 4, gradient: 'from-emerald-500 via-teal-600 to-cyan-700' },
  { id: 5, gradient: 'from-amber-500 via-orange-600 to-red-700' },
  { id: 6, gradient: 'from-pink-600 via-rose-700 to-red-800' },
  { id: 7, gradient: 'from-cyan-500 via-blue-600 to-indigo-700' },
  { id: 8, gradient: 'from-fuchsia-600 via-purple-700 to-blue-800' },
];

const GENRES = ['Fantasy', 'Romance', 'Thriller', 'Science-Fiction', 'Mystère', 'Horreur', 'Contemporain', 'Aventure', 'Historique', 'Poésie'];

const VISIBILITY = [
  { id: 'private', icon: Lock, label: 'Privé', desc: 'Visible uniquement par vous' },
  { id: 'beta', icon: Users, label: 'Bêta-test', desc: 'Accessible aux bêta-lecteurs' },
  { id: 'public', icon: Globe, label: 'Public', desc: 'Visible par toute la communauté' },
];

export function CreateBookPage({ onNavigate }: CreateBookPageProps) {
  const [selectedCover, setSelectedCover] = useState(1);
  const [title, setTitle] = useState('');
  const [genre, setGenre] = useState('');
  const [language, setLanguage] = useState('Français');
  const [summary, setSummary] = useState('');
  const [tags, setTags] = useState('');
  const [visibility, setVisibility] = useState('private');
  const [mature, setMature] = useState(false);

  const selectedGradient = COVER_PRESETS.find((c) => c.id === selectedCover)?.gradient ?? COVER_PRESETS[0].gradient;
  const canCreate = title.trim().length > 0 && genre.length > 0;

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <div className="sticky top-0 z-30 bg-background/95 border-b border-border px-4 pt-5 pb-3" style={{ backdropFilter: 'blur(12px)' }}>
        <div className="max-w-2xl mx-auto flex items-center justify-between">
          <button
            onClick={() => onNavigate('write')}
            className="flex items-center gap-2 text-sm font-semibold text-primary hover:opacity-80 transition-opacity"
          >
            <ArrowLeft className="w-4 h-4" />
            Mes histoires
          </button>
          <h1 className="text-base font-bold text-foreground">Nouvelle histoire</h1>
          <button
            onClick={() => canCreate && onNavigate('editor')}
            className={`px-4 py-2 rounded-xl text-sm font-bold transition-all ${
              canCreate ? 'text-white shadow-md hover:opacity-90' : 'bg-muted text-muted-foreground cursor-not-allowed'
            }`}
            style={canCreate ? { background: 'linear-gradient(135deg, #7C5CFF, #9B80FF)' } : undefined}
          >
            Créer
          </button>
        </div>
      </div>

      <div className="max-w-2xl mx-auto px-4 py-6 space-y-8">

        {/* Cover section */}
        <section>
          <h2 className="text-sm font-bold text-foreground mb-4 uppercase tracking-wider">Couverture</h2>
          <div className="flex gap-6 items-start">
            {/* Preview */}
            <div className="shrink-0">
              <div className={`w-28 h-40 rounded-2xl bg-gradient-to-br ${selectedGradient} shadow-xl relative overflow-hidden`}>
                <div className="absolute inset-0 bg-gradient-to-t from-black/50 via-transparent to-transparent" />
                {title && (
                  <div className="absolute bottom-0 left-0 right-0 p-2">
                    <p className="text-white text-[10px] font-bold leading-tight line-clamp-3">{title}</p>
                  </div>
                )}
              </div>
              <button className="mt-2 w-full flex items-center justify-center gap-1.5 py-2 rounded-xl border border-border text-xs font-medium text-muted-foreground hover:bg-muted transition-colors">
                <Camera className="w-3.5 h-3.5" />
                Importer
              </button>
            </div>

            {/* Color presets */}
            <div className="flex-1">
              <p className="text-xs text-muted-foreground mb-3">Choisir une couleur</p>
              <div className="grid grid-cols-4 gap-2">
                {COVER_PRESETS.map((preset) => (
                  <button
                    key={preset.id}
                    onClick={() => setSelectedCover(preset.id)}
                    className={`w-full aspect-[2/3] rounded-xl bg-gradient-to-br ${preset.gradient} relative transition-transform hover:scale-105 ${
                      selectedCover === preset.id ? 'ring-2 ring-primary ring-offset-2 ring-offset-background' : ''
                    }`}
                  >
                    {selectedCover === preset.id && (
                      <div className="absolute inset-0 rounded-xl flex items-center justify-center bg-black/20">
                        <div className="w-5 h-5 rounded-full bg-white flex items-center justify-center">
                          <Check className="w-3 h-3 text-primary" />
                        </div>
                      </div>
                    )}
                  </button>
                ))}
              </div>
            </div>
          </div>
        </section>

        {/* Book info */}
        <section className="space-y-4">
          <h2 className="text-sm font-bold text-foreground uppercase tracking-wider">Informations</h2>

          {/* Title */}
          <div>
            <label className="text-xs font-semibold text-muted-foreground uppercase tracking-wide mb-1.5 block">
              Titre <span className="text-destructive">*</span>
            </label>
            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="Ex: La Nuit Rouge"
              maxLength={100}
              className="w-full px-4 py-3 rounded-xl bg-card border border-border focus:outline-none focus:border-primary/60 text-foreground placeholder:text-muted-foreground text-sm transition-colors"
            />
            <p className="text-xs text-muted-foreground mt-1 text-right">{title.length}/100</p>
          </div>

          {/* Genre */}
          <div>
            <label className="text-xs font-semibold text-muted-foreground uppercase tracking-wide mb-1.5 block">
              Genre <span className="text-destructive">*</span>
            </label>
            <div className="flex flex-wrap gap-2">
              {GENRES.map((g) => (
                <button
                  key={g}
                  onClick={() => setGenre(g)}
                  className={`px-3 py-1.5 rounded-full text-xs font-semibold transition-all ${
                    genre === g ? 'text-white shadow-sm' : 'bg-card border border-border text-muted-foreground hover:border-primary/40 hover:text-foreground'
                  }`}
                  style={genre === g ? { background: 'linear-gradient(135deg, #7C5CFF, #9B80FF)' } : undefined}
                >
                  {g}
                </button>
              ))}
            </div>
          </div>

          {/* Language */}
          <div>
            <label className="text-xs font-semibold text-muted-foreground uppercase tracking-wide mb-1.5 block">Langue</label>
            <select
              value={language}
              onChange={(e) => setLanguage(e.target.value)}
              className="w-full px-4 py-3 rounded-xl bg-card border border-border focus:outline-none focus:border-primary/60 text-foreground text-sm transition-colors"
            >
              {['Français', 'English', 'Español', 'Português', 'Deutsch'].map((l) => (
                <option key={l} value={l}>{l}</option>
              ))}
            </select>
          </div>

          {/* Summary */}
          <div>
            <label className="text-xs font-semibold text-muted-foreground uppercase tracking-wide mb-1.5 block">Résumé</label>
            <textarea
              value={summary}
              onChange={(e) => setSummary(e.target.value)}
              placeholder="Décrivez votre histoire pour attirer les lecteurs..."
              maxLength={500}
              rows={4}
              className="w-full px-4 py-3 rounded-xl bg-card border border-border focus:outline-none focus:border-primary/60 text-foreground placeholder:text-muted-foreground text-sm resize-none transition-colors"
            />
            <p className="text-xs text-muted-foreground mt-1 text-right">{summary.length}/500</p>
          </div>

          {/* Tags */}
          <div>
            <label className="text-xs font-semibold text-muted-foreground uppercase tracking-wide mb-1.5 block">Tags</label>
            <input
              type="text"
              value={tags}
              onChange={(e) => setTags(e.target.value)}
              placeholder="magie, amour, aventure... (séparés par des virgules)"
              className="w-full px-4 py-3 rounded-xl bg-card border border-border focus:outline-none focus:border-primary/60 text-foreground placeholder:text-muted-foreground text-sm transition-colors"
            />
          </div>
        </section>

        {/* Visibility */}
        <section>
          <h2 className="text-sm font-bold text-foreground mb-3 uppercase tracking-wider">Visibilité</h2>
          <div className="space-y-2">
            {VISIBILITY.map(({ id, icon: Icon, label, desc }) => (
              <label
                key={id}
                className={`flex items-center gap-4 p-4 rounded-2xl border cursor-pointer transition-all ${
                  visibility === id ? 'border-primary/50 bg-primary/5' : 'border-border bg-card hover:border-primary/30'
                }`}
              >
                <input type="radio" name="visibility" value={id} checked={visibility === id} onChange={() => setVisibility(id)} className="sr-only" />
                <div
                  className="w-10 h-10 rounded-xl flex items-center justify-center shrink-0"
                  style={{ backgroundColor: visibility === id ? 'rgba(124,92,255,0.15)' : 'rgba(168,168,179,0.1)' }}
                >
                  <Icon className="w-5 h-5" style={{ color: visibility === id ? '#7C5CFF' : '#A8A8B3' }} />
                </div>
                <div className="flex-1">
                  <p className="font-semibold text-sm text-foreground">{label}</p>
                  <p className="text-xs text-muted-foreground">{desc}</p>
                </div>
                <div
                  className={`w-5 h-5 rounded-full border-2 flex items-center justify-center transition-colors ${
                    visibility === id ? 'border-primary bg-primary' : 'border-border'
                  }`}
                >
                  {visibility === id && <div className="w-2 h-2 rounded-full bg-white" />}
                </div>
              </label>
            ))}
          </div>
        </section>

        {/* Mature content */}
        <section>
          <div
            className="flex items-center justify-between p-4 rounded-2xl bg-card border border-border cursor-pointer"
            onClick={() => setMature(!mature)}
          >
            <div>
              <p className="font-semibold text-sm text-foreground">Contenu mature</p>
              <p className="text-xs text-muted-foreground">Violence, thèmes adultes — réservé aux +18</p>
            </div>
            <div
              className={`w-12 h-6 rounded-full transition-colors relative ${mature ? 'bg-primary' : 'bg-muted'}`}
            >
              <div
                className={`absolute top-1 w-4 h-4 rounded-full bg-white shadow transition-transform ${mature ? 'translate-x-7' : 'translate-x-1'}`}
              />
            </div>
          </div>
        </section>

        {/* CTA */}
        <div className="pb-8">
          <button
            onClick={() => canCreate && onNavigate('editor')}
            disabled={!canCreate}
            className={`w-full py-4 rounded-2xl font-bold text-base transition-all ${
              canCreate ? 'text-white shadow-xl hover:opacity-90 hover:scale-[1.02]' : 'bg-muted text-muted-foreground cursor-not-allowed'
            }`}
            style={canCreate ? { background: 'linear-gradient(135deg, #7C5CFF, #9B80FF)' } : undefined}
          >
            Créer et commencer à écrire
          </button>
          {!canCreate && (
            <p className="text-xs text-muted-foreground text-center mt-2">Remplissez le titre et le genre pour continuer</p>
          )}
        </div>
      </div>
    </div>
  );
}
