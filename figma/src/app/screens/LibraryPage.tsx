import { useState } from 'react';
import { Card } from '../components/Card';
import { Badge } from '../components/Badge';
import { Button } from '../components/Button';
import { MobileNav } from '../components/MobileNav';
import { Star, Clock, BookmarkCheck, Download, Heart, MessageSquare, AlertCircle } from 'lucide-react';

interface LibraryPageProps {
  onNavigate: (page: string) => void;
}

export function LibraryPage({ onNavigate }: LibraryPageProps) {
  const [activeTab, setActiveTab] = useState('readings');

  const savedBooks = [
    {
      id: 1,
      title: "Les Chroniques d'Eldoria",
      author: 'Sophie Martin',
      progress: 65,
      cover: 'bg-gradient-to-br from-purple-600 to-pink-600',
      lastRead: 'Il y a 2 heures',
      rating: 5,
    },
    {
      id: 2,
      title: 'Au-delà des Étoiles',
      author: 'Marc Dubois',
      progress: 23,
      cover: 'bg-gradient-to-br from-blue-600 to-cyan-600',
      lastRead: 'Hier',
      rating: 4,
    },
    {
      id: 3,
      title: 'Le Dernier Refuge',
      author: 'Emma Laurent',
      progress: 100,
      cover: 'bg-gradient-to-br from-red-600 to-orange-600',
      lastRead: 'Il y a 3 jours',
      rating: 5,
    },
  ];

  const favoriteBooks = [
    {
      id: 1,
      title: "Les Chroniques d'Eldoria",
      author: 'Sophie Martin',
      cover: 'bg-gradient-to-br from-purple-600 to-pink-600',
      rating: 5,
    },
    {
      id: 2,
      title: 'Le Dernier Refuge',
      author: 'Emma Laurent',
      cover: 'bg-gradient-to-br from-red-600 to-orange-600',
      rating: 5,
    },
  ];

  const betaReadings = [
    {
      id: 1,
      title: 'La Nuit Rouge',
      author: 'Kevin Fonkou',
      status: 'À lire',
      deadline: '12 juin',
      cover: 'bg-gradient-to-br from-red-600 to-orange-600',
      chaptersRead: 0,
      totalChapters: 8,
    },
    {
      id: 2,
      title: 'Les Ombres de Minuit',
      author: 'Sophie Martin',
      status: 'Retour en cours',
      deadline: '20 juin',
      cover: 'bg-gradient-to-br from-indigo-600 to-purple-600',
      chaptersRead: 5,
      totalChapters: 10,
    },
  ];

  const tabs = [
    { id: 'readings', label: 'Mes lectures' },
    { id: 'favorites', label: 'Favoris' },
    { id: 'beta', label: 'Bêta-lectures' },
  ];

  return (
    <div className="min-h-screen bg-background pb-20 md:pb-8">
      <div className="max-w-7xl mx-auto px-4 py-8 space-y-8">
        <div>
          <h1 className="text-4xl font-bold text-foreground">Bibliothèque</h1>
          <p className="text-muted-foreground mt-2">
            Tous vos livres au même endroit
          </p>
        </div>

        <div className="flex gap-2 overflow-x-auto pb-2">
          {tabs.map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`relative px-8 py-3 rounded-xl whitespace-nowrap transition-all font-medium ${
                activeTab === tab.id
                  ? 'bg-primary text-primary-foreground shadow-lg shadow-primary/30'
                  : 'text-muted-foreground hover:bg-muted hover:text-foreground'
              }`}
            >
              {tab.label}
              {activeTab === tab.id && (
                <div className="absolute bottom-0 left-1/2 -translate-x-1/2 translate-y-1/2 w-2 h-2 bg-primary rounded-full" />
              )}
            </button>
          ))}
        </div>

        {activeTab === 'readings' && (
          <div className="space-y-6">
            <div className="grid grid-cols-1 gap-6">
              {savedBooks.map((book) => (
                <Card
                  key={book.id}
                  hover
                  className="overflow-hidden group border-l-4 border-l-primary"
                  onClick={() => onNavigate('book-reader')}
                >
                  <div className="flex gap-6">
                    <div className={`w-24 h-32 md:w-28 md:h-36 rounded-2xl ${book.cover} shrink-0 shadow-xl group-hover:scale-105 transition-transform`} />

                    <div className="flex-1 space-y-4">
                      <div className="flex items-start justify-between">
                        <div>
                          <h3 className="text-xl font-bold group-hover:text-primary transition-colors mb-1">
                            {book.title}
                          </h3>
                          <p className="text-sm text-muted-foreground">par {book.author}</p>
                        </div>
                        {book.progress === 100 ? (
                          <Badge variant="published">
                            <BookmarkCheck className="w-3 h-3 mr-1" />
                            Terminé ✓
                          </Badge>
                        ) : (
                          <Badge variant="beta">📖 En cours</Badge>
                        )}
                      </div>

                      <div className="space-y-2 bg-purple-50 rounded-xl p-4">
                        <div className="flex items-center justify-between text-sm">
                          <span className="font-medium text-muted-foreground">Progression de lecture</span>
                          <span className="font-bold text-primary">{book.progress}%</span>
                        </div>
                        <div className="h-3 bg-white rounded-full overflow-hidden border border-primary/20">
                          <div
                            className="h-full bg-gradient-to-r from-primary to-purple-600 transition-all"
                            style={{ width: `${book.progress}%` }}
                          />
                        </div>
                      </div>

                      <div className="flex items-center gap-6 text-sm">
                        <div className="flex items-center gap-2 text-muted-foreground">
                          <Clock className="w-4 h-4" />
                          <span>Lu {book.lastRead}</span>
                        </div>
                        {book.rating && (
                          <div className="flex items-center gap-2">
                            <div className="flex">
                              {[...Array(book.rating)].map((_, i) => (
                                <Star key={i} className="w-4 h-4 fill-yellow-400 text-yellow-400" />
                              ))}
                            </div>
                            <span className="font-semibold text-foreground">{book.rating}/5</span>
                          </div>
                        )}
                      </div>
                    </div>
                  </div>
                </Card>
              ))}
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <Card>
                <div className="space-y-2">
                  <p className="text-sm text-muted-foreground">Livres sauvegardés</p>
                  <p className="text-3xl font-bold text-primary">12</p>
                </div>
              </Card>

              <Card>
                <div className="space-y-2">
                  <p className="text-sm text-muted-foreground">Livres terminés</p>
                  <p className="text-3xl font-bold text-accent">8</p>
                </div>
              </Card>

              <Card>
                <div className="space-y-2">
                  <p className="text-sm text-muted-foreground">Temps de lecture total</p>
                  <p className="text-3xl font-bold text-secondary">45h</p>
                </div>
              </Card>
            </div>
          </div>
        )}

        {activeTab === 'favorites' && (
          <div className="space-y-6">
            <div className="bg-gradient-to-r from-red-50 to-pink-50 border border-red-200 rounded-2xl p-6">
              <div className="flex items-start gap-4">
                <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-red-500 to-pink-600 flex items-center justify-center shrink-0">
                  <Heart className="w-7 h-7 text-white fill-white" />
                </div>
                <div>
                  <h3 className="font-semibold text-lg mb-2">Mes Favoris</h3>
                  <p className="text-sm text-muted-foreground">
                    Les livres que vous avez adorés et que vous voulez retrouver facilement
                  </p>
                </div>
              </div>
            </div>

            <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-6">
              {favoriteBooks.map((book) => (
                <Card key={book.id} hover className="p-0 overflow-hidden group relative" onClick={() => onNavigate('book-detail')}>
                  <div className="relative">
                    <div className={`w-full aspect-[2/3] ${book.cover}`} />
                    <div className="absolute top-2 right-2">
                      <div className="w-8 h-8 rounded-full bg-white/90 backdrop-blur-sm flex items-center justify-center shadow-lg">
                        <Heart className="w-4 h-4 fill-red-500 text-red-500" />
                      </div>
                    </div>
                  </div>
                  <div className="p-4 space-y-2">
                    <h4 className="font-semibold text-sm line-clamp-2 group-hover:text-primary transition-colors">
                      {book.title}
                    </h4>
                    <p className="text-xs text-muted-foreground">{book.author}</p>
                    <div className="flex items-center gap-1">
                      {[...Array(book.rating)].map((_, i) => (
                        <Star key={i} className="w-3.5 h-3.5 fill-yellow-400 text-yellow-400" />
                      ))}
                    </div>
                  </div>
                </Card>
              ))}
            </div>
          </div>
        )}

        {activeTab === 'beta' && (
          <div className="space-y-6">
            <div className="bg-gradient-to-r from-purple-50 to-blue-50 border border-primary/20 rounded-2xl p-6">
              <div className="flex items-start gap-4">
                <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-primary to-purple-700 flex items-center justify-center shrink-0">
                  <MessageSquare className="w-7 h-7 text-white" />
                </div>
                <div>
                  <h3 className="font-semibold text-lg mb-2">Espace Bêta-lecture</h3>
                  <p className="text-sm text-muted-foreground">
                    Lisez les manuscrits avant publication et aidez les auteurs avec vos retours constructifs
                  </p>
                </div>
              </div>
            </div>

            <div className="space-y-4">
              {betaReadings.map((book) => (
                <Card key={book.id} hover className="border-l-4 border-l-primary">
                  <div className="flex gap-6">
                    <div className={`w-28 h-36 rounded-2xl ${book.cover} shrink-0 shadow-lg`} />

                    <div className="flex-1 space-y-4">
                      <div>
                        <div className="flex items-start justify-between mb-2">
                          <h3 className="text-xl font-bold">{book.title}</h3>
                          <Badge variant={book.status === 'À lire' ? 'beta' : 'correcting'}>
                            {book.status}
                          </Badge>
                        </div>
                        <p className="text-sm text-muted-foreground">par {book.author}</p>
                      </div>

                      <div className="flex items-center gap-4 text-sm">
                        <div className="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-orange-50 text-orange-700">
                          <Clock className="w-4 h-4" />
                          <span className="font-medium">Deadline : {book.deadline}</span>
                        </div>
                      </div>

                      {book.chaptersRead > 0 && (
                        <div className="space-y-2 bg-muted/30 rounded-xl p-4">
                          <div className="flex items-center justify-between text-sm">
                            <span className="text-muted-foreground">Votre progression</span>
                            <span className="font-semibold">
                              {book.chaptersRead}/{book.totalChapters} chapitres
                            </span>
                          </div>
                          <div className="h-3 bg-white rounded-full overflow-hidden border border-border">
                            <div
                              className="h-full bg-gradient-to-r from-primary to-purple-600 transition-all"
                              style={{ width: `${(book.chaptersRead / book.totalChapters) * 100}%` }}
                            />
                          </div>
                        </div>
                      )}

                      <Button
                        size="lg"
                        variant={book.status === 'À lire' ? 'primary' : 'outline'}
                        onClick={() => onNavigate('beta-reading')}
                      >
                        {book.status === 'À lire' ? '📖 Commencer la lecture' : '📝 Continuer'}
                      </Button>
                    </div>
                  </div>
                </Card>
              ))}
            </div>
          </div>
        )}

      </div>

      <MobileNav currentPage="library" onNavigate={onNavigate} />
    </div>
  );
}
