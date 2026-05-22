import { useState } from 'react';
import { Card } from '../components/Card';
import { Badge } from '../components/Badge';
import { Input } from '../components/Input';
import { Button } from '../components/Button';
import { MobileNav } from '../components/MobileNav';
import { Search, Star, BookmarkPlus, TrendingUp, Clock, Heart, Sparkles } from 'lucide-react';

interface DiscoverPageProps {
  onNavigate: (page: string) => void;
}

export function DiscoverPage({ onNavigate }: DiscoverPageProps) {
  const [searchQuery, setSearchQuery] = useState('');

  const books = [
    {
      id: 1,
      title: "Les Chroniques d'Eldoria",
      author: 'Sophie Martin',
      genre: 'Fantasy',
      rating: 4.8,
      reads: 12500,
      cover: 'bg-gradient-to-br from-purple-600 to-pink-600',
      status: 'published' as const,
    },
    {
      id: 2,
      title: 'Au-delà des Étoiles',
      author: 'Marc Dubois',
      genre: 'Science-Fiction',
      rating: 4.6,
      reads: 8900,
      cover: 'bg-gradient-to-br from-blue-600 to-cyan-600',
      status: 'published' as const,
    },
    {
      id: 3,
      title: 'Le Dernier Refuge',
      author: 'Emma Laurent',
      genre: 'Thriller',
      rating: 4.9,
      reads: 15200,
      cover: 'bg-gradient-to-br from-red-600 to-orange-600',
      status: 'published' as const,
    },
    {
      id: 4,
      title: 'Cœurs Enchevêtrés',
      author: 'Julie Petit',
      genre: 'Romance',
      rating: 4.7,
      reads: 10800,
      cover: 'bg-gradient-to-br from-pink-600 to-rose-600',
      status: 'published' as const,
    },
    {
      id: 5,
      title: 'Les Secrets de Minuit',
      author: 'Thomas Moreau',
      genre: 'Mystère',
      rating: 4.5,
      reads: 7600,
      cover: 'bg-gradient-to-br from-indigo-600 to-purple-600',
      status: 'published' as const,
    },
    {
      id: 6,
      title: 'La Prophétie Oubliée',
      author: 'Claire Bernard',
      genre: 'Fantasy',
      rating: 4.8,
      reads: 11300,
      cover: 'bg-gradient-to-br from-emerald-600 to-teal-600',
      status: 'published' as const,
    },
  ];

  return (
    <div className="min-h-screen bg-background pb-20 md:pb-8">
      <div className="max-w-7xl mx-auto px-4 py-8 space-y-8">
        <div className="space-y-4">
          <h1 className="text-4xl font-bold text-foreground">Découvrir</h1>
          <div className="space-y-3">
            <div className="relative">
              <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
              <input
                type="text"
                placeholder="Rechercher un livre, un auteur, un genre..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-12 pr-4 py-3 rounded-xl bg-card border border-border focus:outline-none focus:ring-2 focus:ring-ring transition-all"
              />
            </div>
            <Button
              variant="outline"
              className="w-full"
              onClick={() => onNavigate('mukeme-recommendation')}
            >
              <Sparkles className="w-5 h-5" />
              Trouver avec Mukeme
            </Button>
          </div>
        </div>

        <div className="flex gap-3 overflow-x-auto pb-2">
          <button className="px-4 py-2 rounded-full bg-primary text-primary-foreground whitespace-nowrap">
            Tous
          </button>
          <button className="px-4 py-2 rounded-full bg-muted text-foreground hover:bg-muted/80 transition-colors whitespace-nowrap">
            Fantasy
          </button>
          <button className="px-4 py-2 rounded-full bg-muted text-foreground hover:bg-muted/80 transition-colors whitespace-nowrap">
            Romance
          </button>
          <button className="px-4 py-2 rounded-full bg-muted text-foreground hover:bg-muted/80 transition-colors whitespace-nowrap">
            Thriller
          </button>
          <button className="px-4 py-2 rounded-full bg-muted text-foreground hover:bg-muted/80 transition-colors whitespace-nowrap">
            Science-Fiction
          </button>
          <button className="px-4 py-2 rounded-full bg-muted text-foreground hover:bg-muted/80 transition-colors whitespace-nowrap">
            Mystère
          </button>
        </div>

        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="text-2xl font-semibold">Tendances du moment</h2>
            <div className="flex items-center gap-2 text-muted-foreground">
              <TrendingUp className="w-5 h-5" />
              <span className="text-sm">Mis à jour aujourd'hui</span>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {books.map((book) => (
              <Card
                key={book.id}
                hover
                className="overflow-hidden"
                onClick={() => onNavigate('book-reader')}
              >
                <div className="flex gap-4">
                  <div className={`w-24 h-32 rounded-xl ${book.cover} shrink-0 shadow-md`} />
                  <div className="flex-1 space-y-2">
                    <div>
                      <h3 className="font-semibold line-clamp-2">{book.title}</h3>
                      <p className="text-sm text-muted-foreground">{book.author}</p>
                    </div>

                    <div className="flex items-center gap-2">
                      <Badge variant="published">{book.genre}</Badge>
                    </div>

                    <div className="flex items-center gap-4 text-sm text-muted-foreground">
                      <div className="flex items-center gap-1">
                        <Star className="w-4 h-4 fill-yellow-400 text-yellow-400" />
                        <span className="font-medium">{book.rating}</span>
                      </div>
                      <div className="flex items-center gap-1">
                        <Clock className="w-4 h-4" />
                        <span>{(book.reads / 1000).toFixed(1)}k</span>
                      </div>
                    </div>
                  </div>

                  <button className="self-start p-2 hover:bg-muted rounded-lg transition-colors">
                    <Heart className="w-5 h-5 text-muted-foreground" />
                  </button>
                </div>
              </Card>
            ))}
          </div>
        </div>

        <div className="space-y-4">
          <h2 className="text-2xl font-semibold">Recommandé pour vous</h2>
          <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-4">
            {books.slice(0, 6).map((book) => (
              <Card
                key={book.id}
                hover
                className="p-0 overflow-hidden"
                onClick={() => onNavigate('book-reader')}
              >
                <div className={`w-full aspect-[2/3] ${book.cover}`} />
                <div className="p-3 space-y-1">
                  <h4 className="font-medium text-sm line-clamp-2">{book.title}</h4>
                  <p className="text-xs text-muted-foreground">{book.author}</p>
                  <div className="flex items-center gap-1 text-xs">
                    <Star className="w-3 h-3 fill-yellow-400 text-yellow-400" />
                    <span className="font-medium">{book.rating}</span>
                  </div>
                </div>
              </Card>
            ))}
          </div>
        </div>
      </div>

      <MobileNav currentPage="discover" onNavigate={onNavigate} />
    </div>
  );
}
