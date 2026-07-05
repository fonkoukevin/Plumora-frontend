import { useState } from 'react';
import { MobileNav } from '../components/MobileNav';
import { Search, Star, Heart, Flame, Sparkles, BookMarked, TrendingUp, Zap } from 'lucide-react';

interface DiscoverPageProps {
  onNavigate: (page: string) => void;
}

const FEATURED = {
  title: 'Le Dernier Refuge',
  author: 'Emma Laurent',
  genre: 'Thriller',
  rating: 4.9,
  reads: '15.2k',
  desc: "Dans un monde ou les secrets valent plus que l'or, une detectives decouvre une verite qui pourrait tout changer.",
  cover: 'from-rose-600 via-red-700 to-slate-900',
};

const GENRES = ['Tous', 'Fantasy', 'Romance', 'Thriller', 'Sci-Fi', 'Mystere', 'Aventure', 'Horreur'];

const TRENDING_BOOKS = [
  { id: 1, title: "Les Chroniques d'Eldoria", author: 'Sophie Martin', rating: 4.8, reads: '12.5k', cover: 'from-violet-500 to-indigo-700', isNew: true },
  { id: 2, title: 'Au-dela des Etoiles', author: 'Marc Dubois', rating: 4.6, reads: '8.9k', cover: 'from-blue-500 to-cyan-700', isNew: false },
  { id: 3, title: 'Le Dernier Refuge', author: 'Emma Laurent', rating: 4.9, reads: '15.2k', cover: 'from-rose-500 to-orange-700', isNew: false },
  { id: 4, title: 'Coeurs Enchevetres', author: 'Julie Petit', rating: 4.7, reads: '10.8k', cover: 'from-pink-500 to-rose-700', isNew: false },
  { id: 5, title: 'Les Secrets de Minuit', author: 'Thomas Moreau', rating: 4.5, reads: '7.6k', cover: 'from-indigo-500 to-purple-700', isNew: false },
  { id: 6, title: 'La Prophetie Oubliee', author: 'Claire Bernard', rating: 4.8, reads: '11.3k', cover: 'from-emerald-500 to-teal-700', isNew: false },
];

const NEW_BOOKS = [
  { id: 1, title: "L'Heritiere des Ombres", author: 'Laura Michel', cover: 'from-amber-500 to-orange-700', rating: 4.3 },
  { id: 2, title: 'Eclats de Lumiere', author: 'Nadia Sow', cover: 'from-yellow-400 to-amber-600', rating: 4.5 },
  { id: 3, title: 'La Cite Perdue', author: 'Antoine Blanc', cover: 'from-teal-500 to-blue-700', rating: 4.2 },
  { id: 4, title: 'Ames en Eclats', author: 'Marie Dupont', cover: 'from-fuchsia-500 to-purple-700', rating: 4.6 },
  { id: 5, title: 'Le Dernier Dragon', author: 'Paul Renard', cover: 'from-red-500 to-rose-700', rating: 4.4 },
];

const GENRE_SECTIONS = [
  {
    genre: 'Fantasy',
    emoji: '🧙',
    books: [
      { id: 1, title: "Les Chroniques d'Eldoria", author: 'Sophie Martin', cover: 'from-violet-500 to-indigo-700', rating: 4.8 },
      { id: 2, title: 'La Prophetie Oubliee', author: 'Claire Bernard', cover: 'from-emerald-500 to-teal-700', rating: 4.8 },
      { id: 3, title: 'Le Dernier Dragon', author: 'Paul Renard', cover: 'from-red-500 to-rose-700', rating: 4.4 },
      { id: 4, title: 'La Cite Perdue', author: 'Antoine Blanc', cover: 'from-teal-500 to-blue-700', rating: 4.2 },
    ],
  },
  {
    genre: 'Romance',
    emoji: '💕',
    books: [
      { id: 1, title: 'Coeurs Enchevetres', author: 'Julie Petit', cover: 'from-pink-500 to-rose-700', rating: 4.7 },
      { id: 2, title: 'Eclats de Lumiere', author: 'Nadia Sow', cover: 'from-yellow-400 to-amber-600', rating: 4.5 },
      { id: 3, title: 'Ames en Eclats', author: 'Marie Dupont', cover: 'from-fuchsia-500 to-purple-700', rating: 4.6 },
      { id: 4, title: "L'Heritiere des Ombres", author: 'Laura Michel', cover: 'from-amber-500 to-orange-700', rating: 4.3 },
    ],
  },
];

export function DiscoverPage({ onNavigate }: DiscoverPageProps) {
  const [activeGenre, setActiveGenre] = useState('Tous');
  const [searchQuery, setSearchQuery] = useState('');

  return (
    <div className="min-h-screen bg-background pb-24 md:pb-8">
      {/* Sticky header */}
      <div
        className="sticky top-0 z-30 px-4 pt-5 pb-3 border-b border-border bg-background/95"
        style={{ backdropFilter: 'blur(12px)' }}
      >
        <div className="max-w-7xl mx-auto">
          <h1
            className="text-xl font-bold text-foreground mb-3"
            style={{ fontFamily: 'var(--font-family-display)' }}
          >
            Decouvrir
          </h1>
          <div className="relative mb-3">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <input
              type="text"
              placeholder="Titre, auteur, genre..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-11 pr-4 py-3 rounded-2xl bg-card border border-border focus:outline-none focus:border-primary/50 transition-all text-sm placeholder:text-muted-foreground"
            />
          </div>
          {/* Mukeme — juste après la recherche */}
          <div
            className="flex items-center gap-4 p-4 rounded-2xl border border-border cursor-pointer hover:border-violet-500/30 transition-colors"
            style={{ background: 'rgba(75,46,131,0.05)' }}
            onClick={() => onNavigate('mukeme-recommendation')}
          >
            <div
              className="w-12 h-12 rounded-2xl flex items-center justify-center shrink-0"
              style={{ background: 'linear-gradient(135deg, #4B2E83, #6B44B8)' }}
            >
              <Sparkles className="w-6 h-6 text-white" />
            </div>
            <div className="flex-1">
              <p className="text-base font-bold text-foreground">Trouver avec Mukeme</p>
              <p className="text-sm text-muted-foreground mt-0.5">Recommandations personnalisees par IA</p>
            </div>
            <div
              className="px-4 py-2 rounded-xl text-sm font-bold text-white shrink-0"
              style={{ background: 'linear-gradient(135deg, #4B2E83, #6B44B8)' }}
            >
              Essayer
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 space-y-8 pt-4">

        {/* Genre filter */}
        <div
          className="flex gap-2 overflow-x-auto pb-1 -mx-4 px-4"
          style={{ scrollbarWidth: 'none' }}
        >
          {GENRES.map((genre) => (
            <button
              key={genre}
              onClick={() => setActiveGenre(genre)}
              className={`shrink-0 px-4 py-2 rounded-full text-sm font-semibold transition-all ${
                activeGenre === genre
                  ? 'text-white shadow-lg shadow-primary/20'
                  : 'bg-card border border-border text-muted-foreground hover:border-primary/40 hover:text-foreground'
              }`}
              style={
                activeGenre === genre
                  ? { background: 'linear-gradient(135deg, #FF6B35, #FF8C5A)' }
                  : undefined
              }
            >
              {genre}
            </button>
          ))}
        </div>

        {/* Trending carousel */}
        <section>
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <TrendingUp className="w-4 h-4 text-primary" />
              <h2 className="text-base font-bold text-foreground">Tendances</h2>
            </div>
            <span className="text-xs text-muted-foreground">Mis a jour aujourd'hui</span>
          </div>

          <div
            className="flex gap-3 overflow-x-auto pb-2 -mx-4 px-4"
            style={{ scrollbarWidth: 'none' }}
          >
            {TRENDING_BOOKS.map((book, i) => (
              <div
                key={book.id}
                className="shrink-0 w-28 cursor-pointer group"
                onClick={() => onNavigate('book-detail')}
              >
                <div className={`w-28 h-40 rounded-2xl bg-gradient-to-br ${book.cover} shadow-lg group-hover:scale-105 transition-transform relative overflow-hidden`}>
                  <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent" />
                  <div
                    className="absolute top-2 left-2 w-5 h-5 rounded-full flex items-center justify-center text-[10px] font-bold text-white shadow"
                    style={{ background: i < 3 ? '#FF6B35' : '#2E2E2E' }}
                  >
                    {i + 1}
                  </div>
                  {book.isNew && (
                    <div className="absolute top-2 right-2 px-1.5 py-0.5 rounded bg-emerald-500/90 text-white text-[9px] font-bold">
                      NEW
                    </div>
                  )}
                  <div className="absolute bottom-0 left-0 right-0 p-2">
                    <div className="flex items-center gap-1">
                      <Star className="w-3 h-3 fill-yellow-400 text-yellow-400" />
                      <span className="text-white text-xs font-bold">{book.rating}</span>
                    </div>
                  </div>
                </div>
                <p className="text-xs font-semibold text-foreground mt-2 line-clamp-2 leading-snug group-hover:text-primary transition-colors">{book.title}</p>
                <p className="text-xs text-muted-foreground mt-0.5">{book.author}</p>
                <p className="text-xs text-muted-foreground/70">{book.reads}</p>
              </div>
            ))}
          </div>
        </section>

        {/* Nouveautes */}
        <section>
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <Zap className="w-4 h-4 text-accent" />
              <h2 className="text-base font-bold text-foreground">Nouveautes</h2>
            </div>
          </div>

          <div
            className="flex gap-3 overflow-x-auto pb-2 -mx-4 px-4"
            style={{ scrollbarWidth: 'none' }}
          >
            {NEW_BOOKS.map((book) => (
              <div
                key={book.id}
                className="shrink-0 w-28 cursor-pointer group"
                onClick={() => onNavigate('book-detail')}
              >
                <div className={`w-28 h-40 rounded-2xl bg-gradient-to-br ${book.cover} shadow-lg group-hover:scale-105 transition-transform relative overflow-hidden`}>
                  <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent" />
                  <div className="absolute top-2 left-2 px-1.5 py-0.5 rounded bg-accent/90 text-black text-[9px] font-bold">
                    NOUVEAU
                  </div>
                  <div className="absolute bottom-0 left-0 right-0 p-2">
                    <div className="flex items-center gap-1">
                      <Star className="w-3 h-3 fill-yellow-400 text-yellow-400" />
                      <span className="text-white text-xs font-bold">{book.rating}</span>
                    </div>
                  </div>
                </div>
                <p className="text-xs font-semibold text-foreground mt-2 line-clamp-2 leading-snug group-hover:text-accent transition-colors">{book.title}</p>
                <p className="text-xs text-muted-foreground mt-0.5">{book.author}</p>
              </div>
            ))}
          </div>
        </section>

        {/* Genre sections */}
        {GENRE_SECTIONS.map((section) => (
          <section key={section.genre}>
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-2">
                <span className="text-lg">{section.emoji}</span>
                <h2 className="text-base font-bold text-foreground">{section.genre}</h2>
              </div>
              <button
                onClick={() => setActiveGenre(section.genre)}
                className="text-xs font-semibold text-primary hover:text-accent transition-colors"
              >
                Voir plus
              </button>
            </div>

            <div className="grid grid-cols-4 gap-3">
              {section.books.map((book) => (
                <div
                  key={book.id}
                  className="cursor-pointer group"
                  onClick={() => onNavigate('book-detail')}
                >
                  <div className={`w-full aspect-[2/3] rounded-xl bg-gradient-to-br ${book.cover} shadow-md group-hover:scale-105 transition-transform relative overflow-hidden`}>
                    <div className="absolute inset-0 bg-gradient-to-t from-black/50 via-transparent to-transparent" />
                    <div className="absolute bottom-0 left-0 right-0 p-1.5">
                      <div className="flex items-center gap-0.5">
                        <Star className="w-2.5 h-2.5 fill-yellow-400 text-yellow-400" />
                        <span className="text-white text-[10px] font-bold">{book.rating}</span>
                      </div>
                    </div>
                  </div>
                  <p className="text-xs font-semibold text-foreground line-clamp-2 mt-1.5 leading-snug group-hover:text-primary transition-colors">{book.title}</p>
                  <p className="text-[10px] text-muted-foreground mt-0.5">{book.author}</p>
                </div>
              ))}
            </div>
          </section>
        ))}

      </div>

      <MobileNav currentPage="discover" onNavigate={onNavigate} />
    </div>
  );
}
