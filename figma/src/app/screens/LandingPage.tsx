import { Feather, Star, BookOpen, Users, TrendingUp, ArrowRight, ChevronRight } from 'lucide-react';

interface LandingPageProps {
  onNavigate: (page: string) => void;
}

const COVERS = [
  { gradient: 'from-violet-600 via-purple-700 to-indigo-800', title: "Les Chroniques d'Eldoria", angle: '-rotate-6' },
  { gradient: 'from-blue-800 via-indigo-800 to-slate-900', title: 'Au-dela des Etoiles', angle: 'rotate-2' },
  { gradient: 'from-rose-500 via-red-600 to-orange-700', title: 'La Nuit Rouge', angle: '-rotate-1' },
  { gradient: 'from-pink-600 via-rose-700 to-red-800', title: "Sang d'Encre", angle: 'rotate-5' },
  { gradient: 'from-emerald-600 via-teal-700 to-cyan-800', title: 'La Prophetie', angle: '-rotate-3' },
];

const GENRES = ['Fantasy', 'Romance', 'Thriller', 'Sci-Fi', 'Mystere', 'Aventure'];

export function LandingPage({ onNavigate }: LandingPageProps) {
  return (
    <div className="min-h-screen flex flex-col bg-background overflow-hidden">
      {/* Nav */}
      <header className="flex items-center justify-between px-6 py-5 relative z-10">
        <div className="flex items-center gap-2.5">
          <div
            className="w-9 h-9 rounded-xl flex items-center justify-center"
            style={{ background: 'linear-gradient(135deg, #4B2E83, #6B44B8)' }}
          >
            <Feather className="w-4 h-4 text-white" />
          </div>
          <span className="text-xl font-bold text-foreground" style={{ fontFamily: 'var(--font-family-display)' }}>
            Plumora
          </span>
        </div>
        <div className="flex items-center gap-3">
          <button
            onClick={() => onNavigate('signup')}
            className="text-sm font-bold px-5 py-2.5 rounded-xl text-white shadow-md hover:shadow-lg hover:scale-105 transition-all"
            style={{ background: 'linear-gradient(135deg, #4B2E83, #6B44B8)' }}
          >
            Se connecter
          </button>
        </div>
      </header>

      {/* Hero */}
      <div className="flex-1 flex flex-col items-center px-6 pt-6 pb-16 relative">
        {/* Subtle glow */}
        <div
          className="absolute top-10 left-1/2 -translate-x-1/2 w-[500px] h-64 rounded-full opacity-10 blur-3xl pointer-events-none"
          style={{ background: 'radial-gradient(ellipse, #4B2E83, transparent)' }}
        />

        {/* Badge */}
        <div className="flex items-center gap-2 px-4 py-1.5 rounded-full border border-primary/20 bg-primary/8 mb-6 relative z-10" style={{ backgroundColor: 'rgba(75,46,131,0.08)' }}>
          <Star className="w-3.5 h-3.5 text-accent fill-accent" />
          <span className="text-xs font-bold text-primary">+50 000 histoires vous attendent</span>
        </div>

        {/* Title */}
        <h1
          className="text-4xl md:text-6xl font-bold text-center mb-4 relative z-10 leading-tight"
          style={{ fontFamily: 'var(--font-family-display)' }}
        >
          <span className="text-foreground">Votre prochaine</span>
          <br />
          <span style={{ background: 'linear-gradient(135deg, #4B2E83, #C9A227)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>
            aventure litteraire
          </span>
          <br />
          <span className="text-foreground">commence ici</span>
        </h1>

        <p className="text-base text-muted-foreground text-center max-w-md mb-8 relative z-10">
          Ecrivez, publiez, lisez et collaborez avec une communaute passionnee.
          L'IA Mukeme vous accompagne a chaque etape.
        </p>

        {/* CTAs */}
        <div className="flex flex-col sm:flex-row gap-3 mb-12 relative z-10">
          <button
            onClick={() => onNavigate('signup')}
            className="flex items-center justify-center gap-2 px-8 py-4 rounded-2xl text-white font-bold text-base shadow-lg hover:shadow-xl hover:scale-105 transition-all"
            style={{ background: 'linear-gradient(135deg, #4B2E83, #6B44B8)' }}
          >
            Rejoindre gratuitement
            <ArrowRight className="w-5 h-5" />
          </button>
          <button
            onClick={() => onNavigate('login')}
            className="flex items-center justify-center gap-2 px-8 py-4 rounded-2xl font-semibold text-base border border-border bg-card hover:border-primary/40 transition-all text-foreground"
          >
            <BookOpen className="w-5 h-5 text-primary" />
            Explorer les livres
          </button>
        </div>

        {/* Book covers */}
        <div className="relative w-full max-w-xs h-48 mb-10 z-10">
          {COVERS.map((cover, i) => (
            <div
              key={i}
              className={`absolute w-20 h-32 rounded-xl shadow-2xl ${cover.angle} hover:scale-110 hover:z-20 transition-transform`}
              style={{ left: `${i * 44}px`, top: i % 2 === 0 ? 0 : 16, zIndex: i }}
            >
              <div className={`w-full h-full rounded-xl bg-gradient-to-br ${cover.gradient}`} />
              <div className="absolute inset-0 rounded-xl bg-gradient-to-t from-black/60 via-transparent to-transparent flex items-end p-1.5">
                <span className="text-white text-[8px] font-medium leading-tight line-clamp-2">{cover.title}</span>
              </div>
            </div>
          ))}
          <div
            className="absolute inset-0 pointer-events-none"
            style={{ background: 'linear-gradient(to right, #F8F7F3 0%, transparent 15%, transparent 85%, #F8F7F3 100%)' }}
          />
        </div>

        {/* Genre pills */}
        <div className="flex flex-wrap gap-2 justify-center mb-10 relative z-10">
          {GENRES.map((genre) => (
            <button
              key={genre}
              onClick={() => onNavigate('discover')}
              className="px-4 py-1.5 rounded-full text-sm font-medium border border-border bg-card hover:border-primary/50 hover:text-primary transition-all text-muted-foreground shadow-sm"
            >
              {genre}
            </button>
          ))}
        </div>

        {/* Stats */}
        <div className="grid grid-cols-3 gap-4 w-full max-w-xs relative z-10">
          {[
            { icon: BookOpen, value: '50k+', label: 'Histoires' },
            { icon: Users, value: '12k+', label: 'Auteurs' },
            { icon: TrendingUp, value: '200k+', label: 'Lecteurs' },
          ].map(({ icon: Icon, value, label }) => (
            <div key={label} className="flex flex-col items-center gap-1 p-4 rounded-2xl border border-border bg-card shadow-sm">
              <Icon className="w-4 h-4 text-primary mb-1" />
              <span className="text-lg font-bold text-foreground">{value}</span>
              <span className="text-xs text-muted-foreground">{label}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Feature cards */}
      <div className="px-6 pb-16 relative z-10">
        <div className="max-w-4xl mx-auto grid grid-cols-1 md:grid-cols-3 gap-4">
          {[
            { emoji: '✍️', title: 'Ecrire', desc: "Editeur puissant avec IA pour creer vos histoires sans limites", accent: '#4B2E83' },
            { emoji: '🔍', title: 'Decouvrir', desc: 'Mukeme vous recommande les livres parfaits selon vos gouts', accent: '#16213E' },
            { emoji: '📚', title: 'Beta-lire', desc: 'Aidez les auteurs et recevez des retours sur vos manuscrits', accent: '#C9A227' },
          ].map((f) => (
            <div
              key={f.title}
              className="rounded-2xl p-5 bg-card border border-border hover:shadow-md hover:scale-105 transition-all cursor-pointer"
              onClick={() => onNavigate('signup')}
            >
              <div className="text-3xl mb-3">{f.emoji}</div>
              <h3 className="font-bold text-foreground mb-1.5">{f.title}</h3>
              <p className="text-sm text-muted-foreground leading-relaxed">{f.desc}</p>
              <div className="mt-3 flex items-center gap-1 text-xs font-semibold" style={{ color: f.accent }}>
                En savoir plus <ChevronRight className="w-3 h-3" />
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
