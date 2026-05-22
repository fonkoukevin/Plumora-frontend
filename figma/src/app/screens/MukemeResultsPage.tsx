import { Card } from '../components/Card';
import { Button } from '../components/Button';
import { Badge } from '../components/Badge';
import { ArrowLeft, Sparkles, Star, BookOpen, Heart } from 'lucide-react';

interface MukemeResultsPageProps {
  onNavigate: (page: string) => void;
}

export function MukemeResultsPage({ onNavigate }: MukemeResultsPageProps) {
  const recommendations = [
    {
      id: 1,
      title: 'La Nuit Rouge',
      author: 'Kevin Fonkou',
      genre: 'Thriller',
      cover: 'bg-gradient-to-br from-red-600 to-orange-600',
      matchScore: 94,
      rating: 4.7,
      reads: 1240,
      duration: '2h30',
      reasons: [
        'Correspond à ton envie de suspense',
        'Lecture courte',
        'Ambiance sombre',
        'Très apprécié par les lecteurs de thrillers',
      ],
    },
    {
      id: 2,
      title: 'Les Ombres de Minuit',
      author: 'Sophie Martin',
      genre: 'Thriller',
      cover: 'bg-gradient-to-br from-indigo-600 to-purple-600',
      matchScore: 89,
      rating: 4.8,
      reads: 2100,
      duration: '3h15',
      reasons: [
        'Style narratif similaire à tes lectures précédentes',
        'Fin surprenante',
        'Atmosphère mystérieuse',
      ],
    },
    {
      id: 3,
      title: 'Le Dernier Refuge',
      author: 'Emma Laurent',
      genre: 'Thriller',
      cover: 'bg-gradient-to-br from-gray-700 to-gray-900',
      matchScore: 87,
      rating: 4.9,
      reads: 3200,
      duration: '2h45',
      reasons: [
        'Tension croissante tout au long du récit',
        'Personnages complexes',
        'Recommandé par des lecteurs aux goûts similaires',
      ],
    },
  ];

  return (
    <div className="min-h-screen bg-background pb-8">
      <div className="max-w-6xl mx-auto px-4 py-8 space-y-8">
        <button
          onClick={() => onNavigate('mukeme-recommendation')}
          className="flex items-center gap-2 text-muted-foreground hover:text-foreground transition-colors"
        >
          <ArrowLeft className="w-5 h-5" />
          Nouvelle recherche
        </button>

        <div className="text-center space-y-2">
          <div className="flex items-center justify-center gap-2">
            <Sparkles className="w-8 h-8 text-primary" />
            <h1 className="text-4xl font-bold text-foreground">Sélection personnalisée</h1>
          </div>
          <p className="text-muted-foreground">
            Mukeme a trouvé {recommendations.length} livres parfaits pour toi
          </p>
        </div>

        <div className="space-y-6">
          {recommendations.map((book) => (
            <Card key={book.id} className="overflow-hidden">
              <div className="flex flex-col md:flex-row gap-6">
                <div className={`w-full md:w-48 h-64 md:h-auto rounded-xl ${book.cover} shrink-0`} />

                <div className="flex-1 space-y-4">
                  <div>
                    <div className="flex items-start justify-between mb-2">
                      <div>
                        <h2 className="text-2xl font-bold">{book.title}</h2>
                        <p className="text-muted-foreground">{book.author}</p>
                      </div>
                      <div className="text-right">
                        <div className="flex items-center gap-2 mb-1">
                          <Sparkles className="w-5 h-5 text-primary" />
                          <span className="text-2xl font-bold text-primary">
                            {book.matchScore}%
                          </span>
                        </div>
                        <p className="text-xs text-muted-foreground">Correspondance</p>
                      </div>
                    </div>

                    <div className="flex flex-wrap gap-2 mb-3">
                      <Badge variant="published">{book.genre}</Badge>
                      <Badge variant="draft">{book.duration}</Badge>
                    </div>

                    <div className="flex items-center gap-4 text-sm text-muted-foreground">
                      <div className="flex items-center gap-1">
                        <Star className="w-4 h-4 fill-yellow-400 text-yellow-400" />
                        <span className="font-medium">{book.rating}</span>
                      </div>
                      <div className="flex items-center gap-1">
                        <BookOpen className="w-4 h-4" />
                        <span>{book.reads.toLocaleString()} lectures</span>
                      </div>
                    </div>
                  </div>

                  <div className="bg-purple-50 rounded-xl p-4">
                    <div className="flex items-center gap-2 mb-3">
                      <Sparkles className="w-5 h-5 text-primary" />
                      <h3 className="font-semibold">Pourquoi ce livre ?</h3>
                    </div>
                    <ul className="space-y-2">
                      {book.reasons.map((reason, index) => (
                        <li key={index} className="flex items-start gap-2 text-sm">
                          <span className="text-primary mt-1">•</span>
                          <span>{reason}</span>
                        </li>
                      ))}
                    </ul>
                  </div>

                  <div className="flex gap-3">
                    <Button className="flex-1" onClick={() => onNavigate('book-detail')}>
                      <BookOpen className="w-4 h-4" />
                      En savoir plus
                    </Button>
                    <Button variant="outline">
                      <Heart className="w-4 h-4" />
                      Ajouter à ma liste
                    </Button>
                  </div>
                </div>
              </div>
            </Card>
          ))}
        </div>

        <div className="text-center">
          <Button variant="outline" onClick={() => onNavigate('mukeme-recommendation')}>
            Affiner la recherche
          </Button>
        </div>
      </div>
    </div>
  );
}
