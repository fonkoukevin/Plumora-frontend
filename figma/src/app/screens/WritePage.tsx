import { useState } from 'react';
import { Card } from '../components/Card';
import { Button } from '../components/Button';
import { MobileNav } from '../components/MobileNav';
import {
  Plus,
  Clock,
  MessageSquare,
  CheckCircle,
  TrendingUp,
  DollarSign,
  Eye,
  Upload,
  Trash2,
  Edit2,
} from 'lucide-react';

interface WritePageProps {
  onNavigate: (page: string) => void;
}

export function WritePage({ onNavigate }: WritePageProps) {
  const [activeTab, setActiveTab] = useState('manuscripts');
  const [deleteConfirm, setDeleteConfirm] = useState<number | null>(null);

  const handleDelete = (id: number) => {
    // Ici on supprimerait le manuscrit
    console.log('Suppression du manuscrit:', id);
    setDeleteConfirm(null);
  };

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

  const feedbacks = [
    {
      id: 1,
      book: 'Les Ombres de Minuit',
      type: 'Incohérence',
      chapter: 'Chapitre 3',
      beta: 'Sarah Dubois',
      priority: 'high',
    },
    {
      id: 2,
      book: 'Les Ombres de Minuit',
      type: 'Rythme lent',
      chapter: 'Chapitre 2',
      beta: 'Marc Lambert',
      priority: 'medium',
    },
  ];

  const earnings = [
    { title: "Sang d'Encre", reads: 2500, amount: 87.5 },
    { title: 'Les Ombres de Minuit', reads: 1800, amount: 63.0 },
  ];

  const tabs = [
    { id: 'manuscripts', label: 'Mes manuscrits' },
    { id: 'feedback', label: 'Retours bêta' },
    { id: 'publication', label: 'Publication' },
  ];

  return (
    <div className="min-h-screen bg-background pb-20 md:pb-8">
      <div className="max-w-7xl mx-auto px-4 py-8 space-y-8">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-4xl font-bold text-foreground">Écrire</h1>
            <p className="text-muted-foreground mt-2">
              Gérez vos manuscrits et votre activité d'auteur
            </p>
          </div>
          <Button size="lg" onClick={() => onNavigate('create-book')}>
            <Plus className="w-5 h-5" />
            Nouveau livre
          </Button>
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

        {activeTab === 'manuscripts' && (
          <div className="space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {manuscripts.map((manuscript) => (
                <Card key={manuscript.id} hover className="group relative overflow-hidden">
                  <div className="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-primary/10 to-transparent rounded-bl-full -mr-16 -mt-16" />

                  <div className="relative space-y-4">
                    <div className="flex items-start justify-between">
                      <h3 className="text-xl font-bold pr-4">{manuscript.title}</h3>
                      <div className="flex items-center gap-2">
                        <button
                          onClick={() => onNavigate('create-book')}
                          className="w-8 h-8 rounded-lg hover:bg-primary/10 flex items-center justify-center transition-colors"
                          title="Éditer"
                        >
                          <Edit2 className="w-4 h-4 text-primary" />
                        </button>
                        <button
                          onClick={() => setDeleteConfirm(manuscript.id)}
                          className="w-8 h-8 rounded-lg hover:bg-destructive/10 flex items-center justify-center transition-colors"
                          title="Supprimer"
                        >
                          <Trash2 className="w-4 h-4 text-destructive" />
                        </button>
                      </div>
                    </div>

                    <div className="space-y-3">
                      {manuscript.status === 'draft' && (
                        <>
                          <div className="flex items-center gap-2 text-sm text-muted-foreground bg-muted/30 rounded-lg px-3 py-2">
                            <Clock className="w-4 h-4" />
                            Modifié {manuscript.lastModified.toLowerCase()}
                          </div>
                          <div className="space-y-2 bg-amber-50 rounded-xl p-4">
                            <div className="flex items-center justify-between text-sm">
                              <span className="text-muted-foreground font-medium">Progression</span>
                              <span className="font-bold text-primary">{manuscript.progress}%</span>
                            </div>
                            <div className="h-3 bg-white rounded-full overflow-hidden border border-primary/20">
                              <div
                                className="h-full bg-gradient-to-r from-primary to-amber-700 transition-all"
                                style={{ width: `${manuscript.progress}%` }}
                              />
                            </div>
                          </div>
                        </>
                      )}

                      {manuscript.status === 'beta' && (
                        <div className="flex items-center gap-2 bg-blue-50 text-blue-700 rounded-lg px-4 py-3">
                          <MessageSquare className="w-5 h-5" />
                          <span className="font-semibold">{manuscript.feedbackCount} retours reçus</span>
                        </div>
                      )}

                      {manuscript.status === 'ready' && (
                        <div className="flex items-center gap-2 bg-green-50 text-green-700 rounded-lg px-4 py-3">
                          <CheckCircle className="w-5 h-5" />
                          <span className="font-semibold">Prêt pour la publication</span>
                        </div>
                      )}
                    </div>

                    <Button
                      className="w-full"
                      size="lg"
                      variant={manuscript.status === 'ready' ? 'primary' : 'outline'}
                      onClick={() => {
                        if (manuscript.status === 'draft') {
                          // Utiliser l'éditeur mobile sur petits écrans
                          const isMobile = window.innerWidth < 768;
                          onNavigate(isMobile ? 'mobile-editor' : 'editor');
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
        )}

        {activeTab === 'feedback' && (
          <div className="space-y-6">
            <div className="flex items-center justify-between">
              <h2 className="text-2xl font-bold">Retours bêta récents</h2>
              <Button variant="outline" onClick={() => onNavigate('beta-feedback')}>
                Voir tout
              </Button>
            </div>

            {feedbacks.length > 0 ? (
              <div className="space-y-4">
                {feedbacks.map((feedback) => (
                  <Card key={feedback.id} hover onClick={() => onNavigate('beta-feedback')} className="border-l-4 border-l-primary">
                    <div className="flex items-start justify-between gap-4">
                      <div className="flex-1">
                        <div className="flex items-center gap-2 mb-3">
                          <Badge variant="beta">{feedback.chapter}</Badge>
                          <Badge
                            variant={
                              feedback.priority === 'high'
                                ? 'rejected'
                                : 'correcting'
                            }
                          >
                            {feedback.type}
                          </Badge>
                        </div>
                        <h3 className="font-bold text-lg mb-1">{feedback.book}</h3>
                        <p className="text-sm text-muted-foreground">Par {feedback.beta}</p>
                      </div>
                      <Button variant="outline" size="sm">
                        Ouvrir →
                      </Button>
                    </div>
                  </Card>
                ))}
              </div>
            ) : (
              <div className="text-center py-20">
                <div className="w-24 h-24 mx-auto rounded-full bg-gradient-to-br from-blue-50 to-amber-50 flex items-center justify-center mb-6">
                  <MessageSquare className="w-12 h-12 text-primary" />
                </div>
                <h3 className="text-xl font-bold mb-3">Aucun retour bêta pour le moment</h3>
                <p className="text-sm text-muted-foreground max-w-md mx-auto mb-6">
                  Envoyez vos manuscrits en bêta-test pour recevoir des retours constructifs de la communauté
                </p>
                <Button onClick={() => onNavigate('beta-submission')}>
                  Envoyer en bêta-test
                </Button>
              </div>
            )}
          </div>
        )}

        {activeTab === 'publication' && (
          <div className="space-y-6">
            <Card className="border-l-4 border-l-primary">
              <div className="flex items-start gap-4">
                <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-primary to-amber-800 flex items-center justify-center shrink-0">
                  <Upload className="w-7 h-7 text-white" />
                </div>
                <div className="flex-1">
                  <h3 className="text-lg font-semibold mb-2">Prêt à publier ?</h3>
                  <p className="text-sm text-muted-foreground mb-4">
                    Vos manuscrits prêts pour la publication apparaîtront ici. Complétez
                    tous les éléments requis avant de soumettre.
                  </p>
                  {manuscripts.filter((m) => m.status === 'ready').length > 0 && (
                    <Button onClick={() => onNavigate('publication-prep')}>
                      <Upload className="w-4 h-4" />
                      Soumettre un livre
                    </Button>
                  )}
                </div>
              </div>
            </Card>

            {manuscripts.filter((m) => m.status === 'ready').length === 0 && (
              <div className="text-center py-16">
                <div className="w-20 h-20 mx-auto rounded-full bg-muted/50 flex items-center justify-center mb-4">
                  <Upload className="w-10 h-10 text-muted-foreground" />
                </div>
                <h3 className="font-semibold text-lg mb-2">Aucun livre prêt</h3>
                <p className="text-sm text-muted-foreground max-w-md mx-auto">
                  Terminez l'écriture et les corrections pour préparer votre livre à la publication
                </p>
              </div>
            )}
          </div>
        )}
      </div>

      {/* Modale de confirmation de suppression */}
      {deleteConfirm !== null && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-card rounded-2xl p-6 max-w-md w-full shadow-xl">
            <div className="flex items-start gap-4 mb-6">
              <div className="w-12 h-12 rounded-xl bg-destructive/10 flex items-center justify-center shrink-0">
                <Trash2 className="w-6 h-6 text-destructive" />
              </div>
              <div className="flex-1">
                <h3 className="font-bold text-lg mb-2">Supprimer ce manuscrit ?</h3>
                <p className="text-sm text-muted-foreground">
                  Cette action est irréversible. Le manuscrit sera définitivement supprimé.
                </p>
              </div>
            </div>
            <div className="flex gap-3">
              <Button
                variant="outline"
                className="flex-1"
                onClick={() => setDeleteConfirm(null)}
              >
                Annuler
              </Button>
              <Button
                className="flex-1 bg-destructive hover:bg-destructive/90"
                onClick={() => handleDelete(deleteConfirm)}
              >
                <Trash2 className="w-4 h-4" />
                Supprimer
              </Button>
            </div>
          </div>
        </div>
      )}

      <MobileNav currentPage="write" onNavigate={onNavigate} />
    </div>
  );
}
