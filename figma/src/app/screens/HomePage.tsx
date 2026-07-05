import { MobileNav } from '../components/MobileNav';
import {
  Bell, User, Star, ChevronRight, Clock, Flame, Sparkles,
  BookOpen, PenTool, MessageSquare, Zap, Quote, Feather,
} from 'lucide-react';

interface HomePageProps {
  onNavigate: (page: string) => void;
}

const CONTINUE_READING = {
  title: 'La Nuit Rouge',
  author: 'Kevin Fonkou',
  chapter: 'Chapitre 3 — La rencontre',
  progress: 35,
  cover: 'from-violet-700 via-purple-800 to-indigo-900',
};

const TRENDING = [
  { id: 1, title: "Les Chroniques d'Eldoria", author: 'Sophie Martin', rating: 4.8, reads: '12.5k', cover: 'from-violet-600 to-indigo-800' },
  { id: 2, title: 'Au-dela des Etoiles', author: 'Marc Dubois', rating: 4.6, reads: '8.9k', cover: 'from-blue-700 to-slate-900' },
  { id: 3, title: 'Le Dernier Refuge', author: 'Emma Laurent', rating: 4.9, reads: '15.2k', cover: 'from-rose-600 to-orange-800' },
  { id: 4, title: 'Coeurs Enchevetres', author: 'Julie Petit', rating: 4.7, reads: '10.8k', cover: 'from-pink-600 to-rose-800' },
  { id: 5, title: 'Les Secrets de Minuit', author: 'Thomas Moreau', rating: 4.5, reads: '7.6k', cover: 'from-indigo-700 to-purple-900' },
];

const MUKEME_PICKS = [
  { id: 1, title: 'La Prophetie Oubliee', author: 'Claire Bernard', cover: 'from-emerald-600 to-teal-800' },
  { id: 2, title: "L'Heritiere des Ombres", author: 'Laura Michel', cover: 'from-amber-600 to-orange-800' },
  { id: 3, title: "Sang d'Encre", author: 'Kevin Fonkou', cover: 'from-slate-700 to-zinc-900' },
  { id: 4, title: 'Eclats de Lumiere', author: 'Nadia Sow', cover: 'from-yellow-500 to-amber-700' },
];

const ACTIVITY = [
  { icon: PenTool, text: 'Chapitre 3 modifie', sub: 'La Nuit Rouge', time: 'Il y a 2h', iconBg: 'rgba(75,46,131,0.1)', iconColor: '#4B2E83', dot: 'bg-primary' },
  { icon: MessageSquare, text: '4 retours beta recus', sub: 'Les Ombres de Minuit', time: 'Hier', iconBg: 'rgba(201,162,39,0.1)', iconColor: '#C9A227', dot: 'bg-accent' },
  { icon: Zap, text: 'Livre publie', sub: "Sang d'Encre", time: 'Il y a 3 jours', iconBg: 'rgba(22,33,62,0.08)', iconColor: '#16213E', dot: 'bg-secondary' },
];

export function HomePage({ onNavigate }: HomePageProps) {
  return (
    <div className="min-h-screen bg-background pb-24 md:pb-8">
      {/* Sticky header */}
      <header
        className="sticky top-0 z-30 px-4 pt-5 pb-3 border-b border-border bg-background/95"
        style={{ backdropFilter: 'blur(12px)' }}
      >
        <div className="max-w-7xl mx-auto space-y-1">
          <div className="flex items-center justify-between">
            {/* Logo */}
            <div className="flex items-center gap-2.5">
              <div
                className="w-10 h-10 rounded-xl flex items-center justify-center"
                style={{ background: 'linear-gradient(135deg, #4B2E83, #6B44B8)' }}
              >
                <Feather className="w-5 h-5 text-white" />
              </div>
              <span className="text-2xl font-bold text-foreground" style={{ fontFamily: 'var(--font-family-display)' }}>Plumora</span>
            </div>
            <div className="flex items-center gap-2">
              <button className="w-9 h-9 rounded-xl hover:bg-muted flex items-center justify-center transition-colors relative">
                <Bell className="w-5 h-5 text-muted-foreground" />
                <span className="absolute top-1.5 right-1.5 w-2 h-2 rounded-full bg-primary" />
              </button>
              <button
                onClick={() => onNavigate('profile')}
                className="w-9 h-9 rounded-xl flex items-center justify-center shadow-md"
                style={{ background: 'linear-gradient(135deg, #4B2E83, #16213E)' }}
              >
                <User className="w-4 h-4 text-white" />
              </button>
            </div>
          </div>
          <p className="text-base font-semibold text-foreground">Bonjour, Kevin 👋</p>
        </div>
      </header>

      <div className="max-w-7xl mx-auto px-4 space-y-7 pt-5">

        {/* Citation */}
        <div className="rounded-2xl p-5 bg-card border border-border shadow-sm">
          <div className="flex items-start gap-4">
            <div className="w-9 h-9 rounded-xl flex items-center justify-center shrink-0" style={{ backgroundColor: 'rgba(75,46,131,0.1)' }}>
              <Quote className="w-4 h-4 text-primary" />
            </div>
            <div>
              <p className="text-foreground italic text-sm leading-relaxed">
                "N'attendez pas l'inspiration. Elle vient en ecrivant."
              </p>
              <p className="text-xs text-muted-foreground mt-2 font-medium">— Victor Hugo</p>
            </div>
          </div>
        </div>

        {/* Continue reading */}
        <div
          className="relative rounded-3xl overflow-hidden cursor-pointer group shadow-lg"
          style={{ minHeight: 180 }}
          onClick={() => onNavigate('book-reader')}
        >
          <div className={`absolute inset-0 bg-gradient-to-br ${CONTINUE_READING.cover}`} />
          <div className="absolute inset-0 bg-gradient-to-r from-black/75 via-black/35 to-transparent" />
          <div className="relative z-10 flex items-end gap-4 p-5" style={{ minHeight: 180 }}>
            <div className={`w-24 h-36 rounded-2xl bg-gradient-to-br ${CONTINUE_READING.cover} shrink-0 shadow-2xl border border-white/20`} />
            <div className="flex-1 pb-1">
              <div className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-white/20 backdrop-blur-sm mb-2">
                <BookOpen className="w-3 h-3 text-white" />
                <span className="text-white text-xs font-semibold">Continuer la lecture</span>
              </div>
              <h2 className="text-white text-xl font-bold leading-tight mb-0.5" style={{ fontFamily: 'var(--font-family-display)' }}>
                {CONTINUE_READING.title}
              </h2>
              <p className="text-white/70 text-xs mb-3">{CONTINUE_READING.chapter}</p>
              <div className="space-y-1">
                <div className="h-1.5 bg-white/20 rounded-full overflow-hidden w-40">
                  <div className="h-full bg-white rounded-full" style={{ width: `${CONTINUE_READING.progress}%` }} />
                </div>
                <p className="text-white/60 text-xs">{CONTINUE_READING.progress}% lu</p>
              </div>
            </div>
            <div className="self-center">
              <div className="w-10 h-10 rounded-full bg-white/20 backdrop-blur-sm flex items-center justify-center group-hover:bg-white/30 transition-colors">
                <ChevronRight className="w-5 h-5 text-white" />
              </div>
            </div>
          </div>
        </div>

        {/* Quick actions */}
        <div className="grid grid-cols-3 gap-3">
          {[
            { label: 'Ecrire', icon: PenTool, page: 'write', bg: 'linear-gradient(135deg, #4B2E83, #6B44B8)' },
            { label: 'Decouvrir', icon: BookOpen, page: 'discover', bg: 'linear-gradient(135deg, #16213E, #1E3A5F)' },
            { label: 'Mukeme', icon: Sparkles, page: 'mukeme', bg: 'linear-gradient(135deg, #C9A227, #E0B830)' },
          ].map(({ label, icon: Icon, page, bg }) => (
            <button
              key={label}
              onClick={() => onNavigate(page)}
              className="flex flex-col items-center gap-2 p-4 rounded-2xl shadow-md hover:shadow-lg hover:scale-105 transition-all"
              style={{ background: bg }}
            >
              <Icon className="w-5 h-5 text-white" />
              <span className="text-white text-xs font-bold">{label}</span>
            </button>
          ))}
        </div>

        {/* Tendances */}
        <section>
          <div className="flex items-center justify-between mb-3">
            <div className="flex items-center gap-2">
              <Flame className="w-4 h-4 text-primary" />
              <h2 className="text-base font-bold text-foreground">Tendances</h2>
            </div>
            <button onClick={() => onNavigate('discover')} className="flex items-center gap-1 text-xs font-semibold text-primary hover:text-accent transition-colors">
              Tout voir <ChevronRight className="w-3.5 h-3.5" />
            </button>
          </div>
          <div className="flex gap-3 overflow-x-auto pb-2 -mx-4 px-4" style={{ scrollbarWidth: 'none' }}>
            {TRENDING.map((book, i) => (
              <div key={book.id} className="shrink-0 w-28 cursor-pointer group" onClick={() => onNavigate('book-detail')}>
                <div className={`w-28 h-40 rounded-2xl bg-gradient-to-br ${book.cover} shadow-md group-hover:scale-105 transition-transform relative overflow-hidden`}>
                  <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent" />
                  <div
                    className="absolute top-2 left-2 w-5 h-5 rounded-full flex items-center justify-center text-[10px] font-bold text-white shadow"
                    style={{ background: i < 3 ? '#C9A227' : '#16213E' }}
                  >
                    {i + 1}
                  </div>
                  <div className="absolute bottom-0 left-0 right-0 p-2">
                    <div className="flex items-center gap-1">
                      <Star className="w-3 h-3 fill-yellow-400 text-yellow-400" />
                      <span className="text-white text-xs font-bold">{book.rating}</span>
                    </div>
                  </div>
                </div>
                <p className="text-xs font-semibold text-foreground mt-2 line-clamp-2 leading-snug group-hover:text-primary transition-colors">{book.title}</p>
                <p className="text-xs text-muted-foreground mt-0.5">{book.author}</p>
              </div>
            ))}
          </div>
        </section>

        {/* Mukeme picks */}
        <section>
          <div className="flex items-center justify-between mb-3">
            <div className="flex items-center gap-2">
              <Sparkles className="w-4 h-4 text-accent" />
              <h2 className="text-base font-bold text-foreground">
                Selection{' '}
                <span style={{ background: 'linear-gradient(135deg, #4B2E83, #C9A227)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>
                  Mukeme
                </span>
              </h2>
            </div>
            <button onClick={() => onNavigate('mukeme-recommendation')} className="flex items-center gap-1 text-xs font-semibold text-primary hover:text-accent transition-colors">
              Personnaliser <ChevronRight className="w-3.5 h-3.5" />
            </button>
          </div>
          <div className="flex gap-3 overflow-x-auto pb-2 -mx-4 px-4" style={{ scrollbarWidth: 'none' }}>
            {MUKEME_PICKS.map((book) => (
              <div key={book.id} className="shrink-0 w-28 cursor-pointer group" onClick={() => onNavigate('book-detail')}>
                <div className={`w-28 h-40 rounded-2xl bg-gradient-to-br ${book.cover} shadow-md group-hover:scale-105 transition-transform relative overflow-hidden`}>
                  <div className="absolute inset-0 bg-gradient-to-t from-black/50 via-transparent to-transparent" />
                  <div className="absolute top-2 right-2 w-6 h-6 rounded-full flex items-center justify-center" style={{ background: 'rgba(201,162,39,0.3)', backdropFilter: 'blur(8px)' }}>
                    <Sparkles className="w-3 h-3 text-yellow-300" />
                  </div>
                </div>
                <p className="text-xs font-semibold text-foreground mt-2 line-clamp-2 leading-snug group-hover:text-primary transition-colors">{book.title}</p>
                <p className="text-xs text-muted-foreground mt-0.5">{book.author}</p>
              </div>
            ))}
          </div>
        </section>

        {/* Activité récente */}
        <section>
          <div className="flex items-center justify-between mb-3">
            <h2 className="text-base font-bold text-foreground">Activite recente</h2>
            <button className="text-xs font-semibold text-primary hover:text-accent transition-colors">Tout voir</button>
          </div>
          <div className="space-y-2">
            {ACTIVITY.map(({ icon: Icon, text, sub, time, iconBg, iconColor, dot }, i) => (
              <div key={i} className="flex items-center gap-4 p-4 rounded-2xl bg-card border border-border hover:shadow-sm transition-all">
                <div className="w-10 h-10 rounded-xl flex items-center justify-center shrink-0" style={{ backgroundColor: iconBg }}>
                  <Icon className="w-5 h-5" style={{ color: iconColor }} />
                </div>
                <div className="flex-1">
                  <p className="text-sm font-semibold text-foreground">{text}</p>
                  <p className="text-xs text-muted-foreground">{sub}</p>
                </div>
                <div className="flex items-center gap-1.5">
                  <div className={`w-1.5 h-1.5 rounded-full ${dot} shrink-0`} />
                  <span className="text-xs text-muted-foreground whitespace-nowrap">{time}</span>
                </div>
              </div>
            ))}
          </div>
        </section>

        {/* Beta banner */}
        <div
          className="rounded-2xl p-5 border border-border bg-card shadow-sm cursor-pointer hover:shadow-md transition-all"
          onClick={() => onNavigate('beta-tests')}
        >
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-2xl flex items-center justify-center shrink-0" style={{ background: 'linear-gradient(135deg, #16213E, #4B2E83)' }}>
              <MessageSquare className="w-6 h-6 text-white" />
            </div>
            <div className="flex-1">
              <p className="font-bold text-foreground">2 beta-lectures en attente</p>
              <p className="text-xs text-muted-foreground mt-0.5">Deadline : 12 juin</p>
            </div>
            <ChevronRight className="w-5 h-5 text-muted-foreground shrink-0" />
          </div>
        </div>

      </div>

      <MobileNav currentPage="home" onNavigate={onNavigate} />
    </div>
  );
}
