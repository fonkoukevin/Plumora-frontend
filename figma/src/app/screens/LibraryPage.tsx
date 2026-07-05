import { useState } from 'react';
import { MobileNav } from '../components/MobileNav';
import { Star, Clock, BookmarkCheck, Heart, MessageSquare, Search, ChevronRight, BarChart3 } from 'lucide-react';

interface LibraryPageProps {
  onNavigate: (page: string) => void;
}

const savedBooks = [
  { id: 1, title: "Les Chroniques d'Eldoria", author: 'Sophie Martin', progress: 65, cover: 'from-violet-500 to-indigo-700', lastRead: 'Il y a 2 heures', rating: 5 },
  { id: 2, title: 'Au-dela des Etoiles', author: 'Marc Dubois', progress: 23, cover: 'from-blue-500 to-cyan-700', lastRead: 'Hier', rating: 4 },
  { id: 3, title: 'Le Dernier Refuge', author: 'Emma Laurent', progress: 100, cover: 'from-rose-500 to-orange-700', lastRead: 'Il y a 3 jours', rating: 5 },
];

const favoriteBooks = [
  { id: 1, title: "Les Chroniques d'Eldoria", author: 'Sophie Martin', cover: 'from-violet-500 to-indigo-700', rating: 5 },
  { id: 2, title: 'Le Dernier Refuge', author: 'Emma Laurent', cover: 'from-rose-500 to-orange-700', rating: 5 },
  { id: 3, title: 'Coeurs Enchevetres', author: 'Julie Petit', cover: 'from-pink-500 to-rose-700', rating: 4 },
  { id: 4, title: 'La Prophetie Oubliee', author: 'Claire Bernard', cover: 'from-emerald-500 to-teal-700', rating: 5 },
];

const betaReadings = [
  { id: 1, title: 'La Nuit Rouge', author: 'Kevin Fonkou', status: 'A lire', deadline: '12 juin', cover: 'from-rose-600 to-orange-700', chaptersRead: 0, totalChapters: 8 },
  { id: 2, title: 'Les Ombres de Minuit', author: 'Sophie Martin', status: 'En cours', deadline: '20 juin', cover: 'from-indigo-600 to-purple-700', chaptersRead: 5, totalChapters: 10 },
];

const TABS = [
  { id: 'readings', label: 'Lectures', emoji: '📖' },
  { id: 'favorites', label: 'Favoris', emoji: '❤️' },
  { id: 'beta', label: 'Beta', emoji: '✍️' },
];

export function LibraryPage({ onNavigate }: LibraryPageProps) {
  const [activeTab, setActiveTab] = useState('readings');
  const [searchQuery, setSearchQuery] = useState('');

  const filterBooks = (books: { title: string; author: string }[]) => {
    if (!searchQuery.trim()) return books;
    const q = searchQuery.toLowerCase();
    return books.filter((b) => b.title.toLowerCase().includes(q) || b.author.toLowerCase().includes(q));
  };

  const filteredReadings = filterBooks(savedBooks) as typeof savedBooks;
  const filteredFavorites = filterBooks(favoriteBooks) as typeof favoriteBooks;
  const filteredBeta = filterBooks(betaReadings) as typeof betaReadings;

  return (
    <div className="min-h-screen bg-background pb-24 md:pb-8">
      {/* Header */}
      <div
        className="sticky top-0 z-30 px-4 pt-5 pb-3 border-b border-border bg-background/95"
        style={{ backdropFilter: 'blur(12px)' }}
      >
        <div className="max-w-7xl mx-auto">
          <h1
            className="text-xl font-bold text-foreground mb-3"
            style={{ fontFamily: 'var(--font-family-display)' }}
          >
            Bibliotheque
          </h1>
          <div className="relative mb-3">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <input
              type="text"
              placeholder="Rechercher un livre ou auteur..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-11 pr-4 py-2.5 rounded-2xl bg-card border border-border focus:outline-none focus:border-primary/50 transition-all text-sm placeholder:text-muted-foreground"
            />
          </div>
          <div className="flex gap-2">
            {TABS.map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`flex items-center gap-1.5 px-4 py-2 rounded-xl text-sm font-bold transition-all ${
                  activeTab === tab.id
                    ? 'text-white shadow-lg shadow-primary/20'
                    : 'bg-card border border-border text-muted-foreground hover:text-foreground hover:border-primary/30'
                }`}
                style={
                  activeTab === tab.id
                    ? { background: 'linear-gradient(135deg, #FF6B35, #FF8C5A)' }
                    : undefined
                }
              >
                {tab.emoji} {tab.label}
              </button>
            ))}
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 pt-4 space-y-5">

        {/* Stats — readings only */}
        {activeTab === 'readings' && (
          <div className="grid grid-cols-3 gap-3">
            {[
              { label: 'Sauvegardes', value: '12', icon: BookmarkCheck, color: 'text-primary' },
              { label: 'Termines', value: '8', icon: BarChart3, color: 'text-accent' },
              { label: 'Temps total', value: '45h', icon: Clock, color: 'text-violet-400' },
            ].map(({ label, value, icon: Icon, color }) => (
              <div key={label} className="p-4 rounded-2xl bg-card border border-border text-center">
                <Icon className={`w-4 h-4 ${color} mx-auto mb-1`} />
                <p className={`text-lg font-bold ${color}`}>{value}</p>
                <p className="text-[10px] text-muted-foreground mt-0.5">{label}</p>
              </div>
            ))}
          </div>
        )}

        {/* READINGS */}
        {activeTab === 'readings' && (
          <div className="space-y-3">
            {filteredReadings.length === 0 ? (
              <EmptyState query={searchQuery} />
            ) : (
              filteredReadings.map((book) => (
                <div
                  key={book.id}
                  className="flex gap-4 p-4 rounded-2xl bg-card border border-border hover:border-primary/30 cursor-pointer group transition-all"
                  onClick={() => onNavigate('book-reader')}
                >
                  <div className={`w-16 h-24 rounded-xl bg-gradient-to-br ${book.cover} shrink-0 shadow-lg group-hover:scale-105 transition-transform`} />
                  <div className="flex-1 min-w-0">
                    <div className="flex items-start justify-between gap-2">
                      <h3 className="font-bold text-foreground text-sm group-hover:text-primary transition-colors line-clamp-2">
                        {book.title}
                      </h3>
                      {book.progress === 100 ? (
                        <div className="shrink-0 flex items-center gap-1 px-2 py-0.5 rounded-full bg-emerald-500/15 text-emerald-400 text-[10px] font-bold">
                          <BookmarkCheck className="w-3 h-3" /> Termine
                        </div>
                      ) : (
                        <div className="shrink-0 px-2 py-0.5 rounded-full bg-primary/15 text-primary text-[10px] font-bold">
                          En cours
                        </div>
                      )}
                    </div>
                    <p className="text-xs text-muted-foreground mt-0.5">par {book.author}</p>
                    <div className="mt-3 space-y-1">
                      <div className="flex items-center justify-between">
                        <span className="text-xs text-muted-foreground">Progression</span>
                        <span className="text-xs font-bold text-primary">{book.progress}%</span>
                      </div>
                      <div className="h-1.5 bg-muted rounded-full overflow-hidden">
                        <div
                          className="h-full rounded-full"
                          style={{ width: `${book.progress}%`, background: 'linear-gradient(90deg, #FF6B35, #FF8C5A)' }}
                        />
                      </div>
                    </div>
                    <div className="flex items-center gap-3 mt-2">
                      <div className="flex items-center gap-1 text-xs text-muted-foreground">
                        <Clock className="w-3 h-3" />
                        {book.lastRead}
                      </div>
                      <div className="flex items-center gap-0.5">
                        {[...Array(book.rating)].map((_, i) => (
                          <Star key={i} className="w-3 h-3 fill-yellow-400 text-yellow-400" />
                        ))}
                      </div>
                    </div>
                  </div>
                </div>
              ))
            )}
          </div>
        )}

        {/* FAVORITES */}
        {activeTab === 'favorites' && (
          <div>
            <div
              className="rounded-2xl p-4 mb-5 border border-border"
              style={{ background: 'linear-gradient(135deg, rgba(239,68,68,0.06), rgba(236,72,153,0.06))' }}
            >
              <div className="flex items-center gap-3">
                <div
                  className="w-10 h-10 rounded-xl flex items-center justify-center shrink-0"
                  style={{ background: 'linear-gradient(135deg, #D94F4F, #B03030)' }}
                >
                  <Heart className="w-5 h-5 text-white fill-white" />
                </div>
                <div>
                  <p className="font-bold text-sm text-foreground">Mes Favoris</p>
                  <p className="text-xs text-muted-foreground">{filteredFavorites.length} livres sauvegardes</p>
                </div>
              </div>
            </div>

            {filteredFavorites.length === 0 ? (
              <EmptyState query={searchQuery} />
            ) : (
              <div className="grid grid-cols-3 gap-3">
                {filteredFavorites.map((book) => (
                  <div
                    key={book.id}
                    className="cursor-pointer group"
                    onClick={() => onNavigate('book-detail')}
                  >
                    <div className={`w-full aspect-[2/3] rounded-2xl bg-gradient-to-br ${book.cover} shadow-lg group-hover:scale-105 transition-transform relative overflow-hidden`}>
                      <div className="absolute inset-0 bg-gradient-to-t from-black/50 via-transparent to-transparent" />
                      <div className="absolute top-2 right-2 w-7 h-7 rounded-full bg-white/20 backdrop-blur-sm flex items-center justify-center">
                        <Heart className="w-3.5 h-3.5 fill-red-400 text-red-400" />
                      </div>
                    </div>
                    <p className="text-xs font-semibold text-foreground mt-2 line-clamp-2 group-hover:text-primary transition-colors">{book.title}</p>
                    <p className="text-[10px] text-muted-foreground mt-0.5">{book.author}</p>
                    <div className="flex items-center gap-0.5 mt-1">
                      {[...Array(book.rating)].map((_, i) => (
                        <Star key={i} className="w-2.5 h-2.5 fill-yellow-400 text-yellow-400" />
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* BETA */}
        {activeTab === 'beta' && (
          <div>
            <div
              className="rounded-2xl p-4 mb-5 border border-border"
              style={{ background: 'linear-gradient(135deg, rgba(91,168,255,0.06), rgba(192,132,252,0.06))' }}
            >
              <div className="flex items-center gap-3">
                <div
                  className="w-10 h-10 rounded-xl flex items-center justify-center shrink-0"
                  style={{ background: 'linear-gradient(135deg, #16213E, #4B2E83)' }}
                >
                  <MessageSquare className="w-5 h-5 text-white" />
                </div>
                <div>
                  <p className="font-bold text-sm text-foreground">Espace Beta-lecture</p>
                  <p className="text-xs text-muted-foreground">Aidez les auteurs avec vos retours</p>
                </div>
              </div>
            </div>

            {filteredBeta.length === 0 ? (
              <EmptyState query={searchQuery} />
            ) : (
              <div className="space-y-3">
                {filteredBeta.map((book) => (
                  <div
                    key={book.id}
                    className="flex gap-4 p-4 rounded-2xl bg-card border border-border hover:border-primary/30 cursor-pointer group transition-all"
                    onClick={() => onNavigate('beta-reading')}
                  >
                    <div className={`w-16 h-24 rounded-xl bg-gradient-to-br ${book.cover} shrink-0 shadow-lg group-hover:scale-105 transition-transform`} />
                    <div className="flex-1 min-w-0">
                      <div className="flex items-start justify-between gap-2">
                        <h3 className="font-bold text-foreground text-sm group-hover:text-primary transition-colors">{book.title}</h3>
                        <div
                          className={`shrink-0 px-2 py-0.5 rounded-full text-[10px] font-bold ${
                            book.status === 'A lire' ? 'bg-primary/15 text-primary' : 'bg-blue-500/15 text-blue-400'
                          }`}
                        >
                          {book.status}
                        </div>
                      </div>
                      <p className="text-xs text-muted-foreground mt-0.5">par {book.author}</p>
                      <div className="flex items-center gap-1.5 mt-2 px-2 py-1 rounded-lg bg-orange-500/10 w-fit">
                        <Clock className="w-3 h-3 text-orange-400" />
                        <span className="text-xs font-semibold text-orange-400">Deadline : {book.deadline}</span>
                      </div>
                      {book.chaptersRead > 0 && (
                        <div className="mt-2 space-y-1">
                          <div className="flex items-center justify-between">
                            <span className="text-xs text-muted-foreground">{book.chaptersRead}/{book.totalChapters} chapitres</span>
                            <span className="text-xs font-bold text-primary">{Math.round((book.chaptersRead / book.totalChapters) * 100)}%</span>
                          </div>
                          <div className="h-1.5 bg-muted rounded-full overflow-hidden">
                            <div
                              className="h-full rounded-full"
                              style={{
                                width: `${(book.chaptersRead / book.totalChapters) * 100}%`,
                                background: 'linear-gradient(90deg, #16213E, #4B2E83)',
                              }}
                            />
                          </div>
                        </div>
                      )}
                    </div>
                    <ChevronRight className="w-4 h-4 text-muted-foreground self-center shrink-0" />
                  </div>
                ))}
              </div>
            )}
          </div>
        )}
      </div>

      <MobileNav currentPage="library" onNavigate={onNavigate} />
    </div>
  );
}

function EmptyState({ query }: { query: string }) {
  return (
    <div className="text-center py-16">
      <div className="w-16 h-16 mx-auto rounded-full bg-card flex items-center justify-center mb-4 border border-border">
        <Search className="w-7 h-7 text-muted-foreground" />
      </div>
      <p className="font-semibold text-foreground mb-1">Aucun resultat</p>
      <p className="text-sm text-muted-foreground">
        {query ? `Aucun livre pour "${query}"` : 'Votre bibliotheque est vide'}
      </p>
    </div>
  );
}
