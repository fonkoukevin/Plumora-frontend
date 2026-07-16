import { AppHeader } from '../components/AppHeader';
import { Card } from '../components/Card';
import { Badge } from '../components/Badge';
import { Button } from '../components/Button';
import { ArrowLeft, Clock, MessageSquare, Star, ThumbsUp, AlertCircle } from 'lucide-react';

interface BetaTestPageProps {
  onNavigate: (page: string) => void;
}

export function BetaTestPage({ onNavigate }: BetaTestPageProps) {
  const betaBooks = [
    {
      id: 1,
      title: 'Le Royaume des Ombres',
      author: 'Marie Durand',
      chaptersAvailable: 8,
      deadline: '3 jours',
      feedbackGiven: 5,
      cover: 'bg-gradient-to-br from-indigo-600 to-purple-600',
      status: 'in-progress',
    },
    {
      id: 2,
      title: 'Au-delà du Temps',
      author: 'Lucas Bernard',
      chaptersAvailable: 12,
      deadline: '1 semaine',
      feedbackGiven: 0,
      cover: 'bg-gradient-to-br from-blue-600 to-teal-600',
      status: 'new',
    },
    {
      id: 3,
      title: 'Les Gardiens de la Nuit',
      author: 'Sophie Martin',
      chaptersAvailable: 10,
      deadline: 'Terminé',
      feedbackGiven: 10,
      cover: 'bg-gradient-to-br from-purple-600 to-pink-600',
      status: 'completed',
    },
  ];

  return (
    <div className="min-h-screen bg-background pb-20 lg:pb-0">
      <AppHeader
        title="Bêta-retours"
        subtitle="Aidez les auteurs avant publication et gagnez en expérience"
        emoji="📖"
        gradient={['#3FBF7F', '#7C5CFF']}
        onNavigate={onNavigate}
      />
      <div className="max-w-7xl mx-auto px-4 py-8 space-y-8">

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <Card>
            <div className="space-y-2">
              <p className="text-sm text-muted-foreground">Livres actifs</p>
              <p className="text-3xl font-bold text-primary">2</p>
            </div>
          </Card>

          <Card>
            <div className="space-y-2">
              <p className="text-sm text-muted-foreground">Retours donnés</p>
              <p className="text-3xl font-bold text-accent">15</p>
            </div>
          </Card>

          <Card>
            <div className="space-y-2">
              <p className="text-sm text-muted-foreground">Livres terminés</p>
              <p className="text-3xl font-bold text-secondary">1</p>
            </div>
          </Card>
        </div>

        <div className="space-y-4">
          <h2 className="text-2xl font-semibold">Manuscrits en cours</h2>

          <div className="space-y-4">
            {betaBooks.map((book) => (
              <Card key={book.id} hover>
                <div className="flex gap-4">
                  <div className={`w-24 h-32 rounded-xl ${book.cover} shrink-0 shadow-md`} />

                  <div className="flex-1 space-y-3">
                    <div className="flex items-start justify-between">
                      <div>
                        <h3 className="font-semibold text-lg">{book.title}</h3>
                        <p className="text-sm text-muted-foreground">par {book.author}</p>
                      </div>
                      {book.status === 'new' && (
                        <Badge variant="beta">Nouveau</Badge>
                      )}
                      {book.status === 'completed' && (
                        <Badge variant="published">Terminé</Badge>
                      )}
                    </div>

                    <div className="flex items-center gap-4 text-sm text-muted-foreground">
                      <div className="flex items-center gap-1">
                        <MessageSquare className="w-4 h-4" />
                        <span>{book.chaptersAvailable} chapitres</span>
                      </div>
                      <div className="flex items-center gap-1">
                        <ThumbsUp className="w-4 h-4" />
                        <span>{book.feedbackGiven} retours donnés</span>
                      </div>
                      {book.status !== 'completed' && (
                        <div className="flex items-center gap-1 text-accent">
                          <Clock className="w-4 h-4" />
                          <span>Deadline : {book.deadline}</span>
                        </div>
                      )}
                    </div>

                    {book.status === 'in-progress' && (
                      <div className="space-y-1">
                        <div className="flex items-center justify-between text-sm">
                          <span className="text-muted-foreground">Progression</span>
                          <span className="font-medium">
                            {book.feedbackGiven}/{book.chaptersAvailable} chapitres
                          </span>
                        </div>
                        <div className="h-2 bg-muted rounded-full overflow-hidden">
                          <div
                            className="h-full bg-primary transition-all"
                            style={{
                              width: `${(book.feedbackGiven / book.chaptersAvailable) * 100}%`,
                            }}
                          />
                        </div>
                      </div>
                    )}

                    <div className="flex gap-2">
                      <Button
                        className="flex-1"
                        variant={book.status === 'completed' ? 'outline' : 'primary'}
                        onClick={() => onNavigate('beta-reading')}
                      >
                        {book.status === 'completed'
                          ? 'Voir mes retours'
                          : 'Continuer la lecture'}
                      </Button>
                      {book.status !== 'completed' && (
                        <Button variant="ghost" onClick={() => onNavigate('beta-reading')}>
                          <MessageSquare className="w-4 h-4" />
                        </Button>
                      )}
                    </div>
                  </div>
                </div>
              </Card>
            ))}
          </div>
        </div>

        <Card className="bg-blue-50 border-blue-200">
          <div className="flex items-start gap-4">
            <div className="w-12 h-12 rounded-xl bg-blue-100 flex items-center justify-center shrink-0">
              <AlertCircle className="w-6 h-6 text-blue-600" />
            </div>
            <div>
              <h3 className="font-semibold mb-2">Conseils pour un bon bêta-test</h3>
              <ul className="text-sm text-muted-foreground space-y-1 list-disc list-inside">
                <li>Soyez constructif et bienveillant dans vos retours</li>
                <li>Notez les incohérences et les points à améliorer</li>
                <li>Partagez ce que vous avez aimé</li>
                <li>Respectez les délais fixés par l'auteur</li>
              </ul>
            </div>
          </div>
        </Card>
      </div>

    </div>
  );
}
