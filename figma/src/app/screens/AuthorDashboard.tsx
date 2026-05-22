import { Card } from '../components/Card';
import { Button } from '../components/Button';
import { Badge } from '../components/Badge';
import { MobileNav } from '../components/MobileNav';
import { Plus, Clock, MessageSquare, CheckCircle, ArrowLeft } from 'lucide-react';

interface AuthorDashboardProps {
  onNavigate: (page: string) => void;
}

export function AuthorDashboard({ onNavigate }: AuthorDashboardProps) {
  const manuscripts = [
    {
      id: 1,
      title: 'La Nuit Rouge',
      status: 'draft' as const,
      progress: 35,
      lastModified: "Aujourd'hui",
      action: 'Continuer',
    },
    {
      id: 2,
      title: 'Les Ombres de Minuit',
      status: 'beta' as const,
      feedbackCount: 12,
      action: 'Voir les retours',
    },
    {
      id: 3,
      title: "Sang d'Encre",
      status: 'ready' as const,
      action: 'Soumettre à publication',
    },
  ];

  return (
    <div className="min-h-screen bg-background pb-20 md:pb-8">
      <div className="max-w-7xl mx-auto px-4 py-8 space-y-8">
        <button
          onClick={() => onNavigate('home')}
          className="flex items-center gap-2 text-muted-foreground hover:text-foreground transition-colors mb-4"
        >
          <ArrowLeft className="w-5 h-5" />
          Retour à l'accueil
        </button>

        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-4xl font-bold text-foreground">Espace Auteur</h1>
            <p className="text-muted-foreground mt-2">
              Gérez vos manuscrits et suivez votre progression
            </p>
          </div>
          <Button size="lg" onClick={() => onNavigate('create-book')}>
            <Plus className="w-5 h-5" />
            Nouveau livre
          </Button>
        </div>

        <div className="space-y-4">
          <h2 className="text-2xl font-semibold">Mes manuscrits</h2>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {manuscripts.map((manuscript) => (
              <Card key={manuscript.id} hover>
                <div className="space-y-4">
                  <div className="flex items-start justify-between">
                    <h3 className="text-xl font-semibold">{manuscript.title}</h3>
                    <Badge variant={manuscript.status}>
                      {manuscript.status === 'draft' && 'Brouillon'}
                      {manuscript.status === 'beta' && 'En bêta-test'}
                      {manuscript.status === 'ready' && 'Prêt à publier'}
                    </Badge>
                  </div>

                  <div className="space-y-2">
                    {manuscript.status === 'draft' && (
                      <>
                        <div className="flex items-center gap-2 text-sm text-muted-foreground">
                          <Clock className="w-4 h-4" />
                          Dernière modification : {manuscript.lastModified}
                        </div>
                        <div className="space-y-1">
                          <div className="flex items-center justify-between text-sm">
                            <span className="text-muted-foreground">Progression</span>
                            <span className="font-medium">{manuscript.progress}%</span>
                          </div>
                          <div className="h-2 bg-muted rounded-full overflow-hidden">
                            <div
                              className="h-full bg-primary transition-all"
                              style={{ width: `${manuscript.progress}%` }}
                            />
                          </div>
                        </div>
                      </>
                    )}

                    {manuscript.status === 'beta' && (
                      <div className="flex items-center gap-2 text-sm text-muted-foreground">
                        <MessageSquare className="w-4 h-4" />
                        {manuscript.feedbackCount} retours reçus
                      </div>
                    )}

                    {manuscript.status === 'ready' && (
                      <div className="flex items-center gap-2 text-sm text-accent">
                        <CheckCircle className="w-4 h-4" />
                        Prêt pour la publication
                      </div>
                    )}
                  </div>

                  <Button
                    className="w-full"
                    variant={manuscript.status === 'ready' ? 'primary' : 'outline'}
                    onClick={() => {
                      if (manuscript.status === 'draft') {
                        onNavigate('editor');
                      } else if (manuscript.status === 'beta') {
                        onNavigate('beta-feedback');
                      } else if (manuscript.status === 'ready') {
                        onNavigate('publication-prep');
                      }
                    }}
                  >
                    {manuscript.action}
                  </Button>
                </div>
              </Card>
            ))}
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <Card>
            <div className="space-y-2">
              <p className="text-sm text-muted-foreground">Total de manuscrits</p>
              <p className="text-3xl font-bold text-primary">3</p>
            </div>
          </Card>

          <Card>
            <div className="space-y-2">
              <p className="text-sm text-muted-foreground">En cours d'écriture</p>
              <p className="text-3xl font-bold text-secondary">1</p>
            </div>
          </Card>

          <Card>
            <div className="space-y-2">
              <p className="text-sm text-muted-foreground">Livres publiés</p>
              <p className="text-3xl font-bold text-accent">1</p>
            </div>
          </Card>
        </div>
      </div>

      <MobileNav currentPage="author-dashboard" onNavigate={onNavigate} />
    </div>
  );
}
