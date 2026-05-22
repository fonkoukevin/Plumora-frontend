import { Card } from '../components/Card';
import { Button } from '../components/Button';
import { Badge } from '../components/Badge';
import {
  ArrowLeft,
  Star,
  BookOpen,
  Clock,
  Heart,
  Share2,
  Sparkles,
  Play,
} from 'lucide-react';

interface BookDetailPageProps {
  onNavigate: (page: string) => void;
}

export function BookDetailPage({ onNavigate }: BookDetailPageProps) {
  return (
    <div className="min-h-screen bg-background pb-8">
      <div className="max-w-6xl mx-auto px-4 py-8 space-y-8">
        <button
          onClick={() => onNavigate('discover')}
          className="flex items-center gap-2 text-muted-foreground hover:text-foreground transition-colors"
        >
          <ArrowLeft className="w-5 h-5" />
          Retour
        </button>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          <div className="md:col-span-1">
            <div className="sticky top-8 space-y-4">
              <div className="w-full aspect-[2/3] bg-gradient-to-br from-red-600 to-orange-600 rounded-2xl shadow-2xl" />

              <div className="space-y-2">
                <Button className="w-full" size="lg" onClick={() => onNavigate('book-reader')}>
                  <Play className="w-5 h-5" />
                  Lire maintenant
                </Button>
                <Button variant="outline" className="w-full">
                  <Heart className="w-5 h-5" />
                  Ajouter aux favoris
                </Button>
                <Button variant="outline" className="w-full">
                  <Share2 className="w-5 h-5" />
                  Partager
                </Button>
              </div>
            </div>
          </div>

          <div className="md:col-span-2 space-y-6">
            <div>
              <h1 className="text-4xl font-bold mb-2">La Nuit Rouge</h1>
              <p className="text-xl text-muted-foreground mb-4">par Kevin Fonkou</p>

              <div className="flex flex-wrap gap-2 mb-6">
                <Badge variant="published">Thriller</Badge>
                <Badge variant="draft">8 chapitres</Badge>
              </div>

              <div className="flex flex-wrap gap-6 text-sm">
                <div className="flex items-center gap-2">
                  <Star className="w-5 h-5 fill-yellow-400 text-yellow-400" />
                  <span className="font-semibold text-lg">4.7</span>
                  <span className="text-muted-foreground">(124 avis)</span>
                </div>
                <div className="flex items-center gap-2">
                  <BookOpen className="w-5 h-5 text-muted-foreground" />
                  <span className="font-medium">1 240 lectures</span>
                </div>
                <div className="flex items-center gap-2">
                  <Clock className="w-5 h-5 text-muted-foreground" />
                  <span className="font-medium">2h30 de lecture</span>
                </div>
              </div>
            </div>

            <Card>
              <h2 className="text-xl font-semibold mb-4">Résumé</h2>
              <p className="text-muted-foreground leading-relaxed">
                Clara découvre un mystère enfoui dans sa famille. Entre enquête palpitante et
                révélations troublantes, elle devra affronter son passé pour comprendre son
                présent.
              </p>
              <p className="text-muted-foreground leading-relaxed mt-4">
                Dans une atmosphère sombre et oppressante, suivez Clara dans sa quête de
                vérité. Chaque indice la rapproche d'un secret qui pourrait tout changer.
                Un thriller psychologique qui vous tiendra en haleine jusqu'à la dernière
                page.
              </p>
            </Card>

            <Card className="bg-purple-50 border-purple-200">
              <div className="flex items-start gap-4">
                <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-primary to-purple-600 flex items-center justify-center shrink-0">
                  <Sparkles className="w-6 h-6 text-white" />
                </div>
                <div className="flex-1">
                  <h3 className="font-semibold mb-3">Pourquoi Mukeme te le recommande</h3>
                  <ul className="space-y-2 text-sm">
                    <li className="flex items-start gap-2">
                      <span className="text-primary mt-1">•</span>
                      <span>Correspond à ton envie de suspense et d'histoires sombres</span>
                    </li>
                    <li className="flex items-start gap-2">
                      <span className="text-primary mt-1">•</span>
                      <span>Durée de lecture courte, idéale pour une session</span>
                    </li>
                    <li className="flex items-start gap-2">
                      <span className="text-primary mt-1">•</span>
                      <span>Très apprécié par les lecteurs qui aiment les thrillers psychologiques</span>
                    </li>
                    <li className="flex items-start gap-2">
                      <span className="text-primary mt-1">•</span>
                      <span>Style d'écriture similaire aux livres que tu as aimés</span>
                    </li>
                  </ul>
                </div>
              </div>
            </Card>

            <Card>
              <h2 className="text-xl font-semibold mb-4">À propos de l'auteur</h2>
              <div className="flex items-start gap-4">
                <div className="w-16 h-16 rounded-full bg-gradient-to-br from-primary to-purple-600 flex items-center justify-center text-white text-xl font-bold shrink-0">
                  KF
                </div>
                <div>
                  <h3 className="font-semibold">Kevin Fonkou</h3>
                  <p className="text-sm text-muted-foreground mt-1">
                    Auteur passionné de thrillers psychologiques. "La Nuit Rouge" est son
                    premier roman publié sur Plumora.
                  </p>
                  <div className="flex gap-4 mt-3 text-sm">
                    <span className="text-muted-foreground">2 livres publiés</span>
                    <span className="text-muted-foreground">•</span>
                    <span className="text-muted-foreground">3 400 lecteurs</span>
                  </div>
                </div>
              </div>
            </Card>

            <Card>
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-xl font-semibold">Avis des lecteurs</h2>
                <Button variant="outline" size="sm">
                  Donner mon avis
                </Button>
              </div>

              <div className="space-y-4">
                <div className="border-b border-border pb-4">
                  <div className="flex items-center gap-2 mb-2">
                    <div className="flex">
                      {[1, 2, 3, 4, 5].map((star) => (
                        <Star key={star} className="w-4 h-4 fill-yellow-400 text-yellow-400" />
                      ))}
                    </div>
                    <span className="font-medium">Sarah D.</span>
                    <span className="text-sm text-muted-foreground">Il y a 2 jours</span>
                  </div>
                  <p className="text-sm text-muted-foreground">
                    Un thriller captivant ! J'ai dévoré le livre en une soirée. Les rebondissements
                    sont bien amenés et la fin m'a vraiment surprise.
                  </p>
                </div>

                <div className="border-b border-border pb-4">
                  <div className="flex items-center gap-2 mb-2">
                    <div className="flex">
                      {[1, 2, 3, 4].map((star) => (
                        <Star key={star} className="w-4 h-4 fill-yellow-400 text-yellow-400" />
                      ))}
                      <Star className="w-4 h-4 text-gray-300" />
                    </div>
                    <span className="font-medium">Marc L.</span>
                    <span className="text-sm text-muted-foreground">Il y a 5 jours</span>
                  </div>
                  <p className="text-sm text-muted-foreground">
                    Très bon roman avec une atmosphère prenante. Quelques longueurs au milieu
                    mais dans l'ensemble une excellente lecture.
                  </p>
                </div>
              </div>

              <button className="text-primary hover:underline text-sm mt-4">
                Voir tous les avis (124)
              </button>
            </Card>
          </div>
        </div>
      </div>
    </div>
  );
}
