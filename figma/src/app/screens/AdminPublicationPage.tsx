import { useState } from 'react';
import { Card } from '../components/Card';
import { Button } from '../components/Button';
import { Badge } from '../components/Badge';
import {
  Shield,
  CheckCircle,
  XCircle,
  Eye,
  FileText,
  Image as ImageIcon,
  Tag,
  AlertTriangle,
} from 'lucide-react';

interface AdminPublicationPageProps {
  onNavigate: (page: string) => void;
}

export function AdminPublicationPage({ onNavigate }: AdminPublicationPageProps) {
  const [showRejectModal, setShowRejectModal] = useState(false);
  const [rejectReason, setRejectReason] = useState('');

  const adminChecklist = [
    { id: 'readable', label: 'Contenu lisible', checked: true },
    { id: 'summary', label: 'Résumé conforme', checked: true },
    { id: 'cover', label: 'Couverture correcte', checked: true },
    { id: 'reports', label: 'Aucun signalement critique', checked: true },
    { id: 'category', label: 'Catégorie adaptée', checked: true },
  ];

  const pendingBooks = [
    {
      id: 1,
      title: 'La Nuit Rouge',
      author: 'Kevin Fonkou',
      genre: 'Thriller',
      submitted: 'Il y a 2 jours',
      chapters: 8,
      cover: 'bg-gradient-to-br from-red-600 to-orange-600',
    },
    {
      id: 2,
      title: 'Au-delà des Étoiles',
      author: 'Marc Dubois',
      genre: 'Science-Fiction',
      submitted: 'Il y a 5 jours',
      chapters: 12,
      cover: 'bg-gradient-to-br from-blue-600 to-cyan-600',
    },
  ];

  const handleApprove = () => {
    onNavigate('home');
  };

  const handleReject = () => {
    setShowRejectModal(false);
    onNavigate('home');
  };

  return (
    <div className="min-h-screen bg-background pb-8">
      <div className="max-w-6xl mx-auto px-4 py-8 space-y-8">
        <div className="flex items-center gap-3">
          <div className="w-12 h-12 rounded-xl bg-purple-100 flex items-center justify-center">
            <Shield className="w-6 h-6 text-primary" />
          </div>
          <div>
            <h1 className="text-4xl font-bold text-foreground">Administration</h1>
            <p className="text-muted-foreground">Publications en attente de validation</p>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <Card>
            <div className="space-y-2">
              <p className="text-sm text-muted-foreground">En attente</p>
              <p className="text-3xl font-bold text-orange-600">2</p>
            </div>
          </Card>

          <Card>
            <div className="space-y-2">
              <p className="text-sm text-muted-foreground">Validés ce mois</p>
              <p className="text-3xl font-bold text-accent">18</p>
            </div>
          </Card>

          <Card>
            <div className="space-y-2">
              <p className="text-sm text-muted-foreground">Refusés ce mois</p>
              <p className="text-3xl font-bold text-destructive">3</p>
            </div>
          </Card>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-1 space-y-4">
            <h2 className="text-xl font-semibold">Livres en attente</h2>
            {pendingBooks.map((book) => (
              <Card key={book.id} hover className="cursor-pointer">
                <div className="flex gap-3">
                  <div className={`w-16 h-20 rounded-lg ${book.cover} shrink-0`} />
                  <div className="flex-1">
                    <h3 className="font-semibold line-clamp-1">{book.title}</h3>
                    <p className="text-sm text-muted-foreground">{book.author}</p>
                    <div className="flex items-center gap-2 mt-2">
                      <Badge variant="beta">{book.genre}</Badge>
                    </div>
                    <p className="text-xs text-muted-foreground mt-1">{book.submitted}</p>
                  </div>
                </div>
              </Card>
            ))}
          </div>

          <div className="lg:col-span-2">
            <Card className="h-full">
              <div className="space-y-6">
                <div className="flex items-start gap-4">
                  <div className="w-32 h-40 bg-gradient-to-br from-red-600 to-orange-600 rounded-xl shrink-0" />
                  <div className="flex-1">
                    <h2 className="text-2xl font-bold mb-2">La Nuit Rouge</h2>
                    <p className="text-muted-foreground mb-4">par Kevin Fonkou</p>
                    <div className="flex flex-wrap gap-2 mb-4">
                      <Badge variant="beta">Thriller</Badge>
                      <Badge variant="draft">8 chapitres</Badge>
                      <Badge variant="ready">En attente de validation</Badge>
                    </div>
                    <p className="text-sm text-muted-foreground">
                      Soumis il y a 2 jours
                    </p>
                  </div>
                </div>

                <div className="space-y-3">
                  <h3 className="font-semibold">Résumé</h3>
                  <p className="text-sm text-muted-foreground leading-relaxed">
                    Clara découvre un mystère enfoui dans sa famille. Entre enquête
                    palpitante et révélations troublantes, elle devra affronter son passé
                    pour comprendre son présent. Un thriller psychologique qui vous tiendra
                    en haleine jusqu'à la dernière page.
                  </p>
                </div>

                <div className="space-y-4">
                  <h3 className="font-semibold flex items-center gap-2">
                    <CheckCircle className="w-5 h-5 text-accent" />
                    Checklist de validation
                  </h3>
                  <div className="space-y-2">
                    {adminChecklist.map((item) => (
                      <div
                        key={item.id}
                        className="flex items-center gap-3 p-3 rounded-xl bg-green-50"
                      >
                        <CheckCircle className="w-5 h-5 text-accent shrink-0" />
                        <span className="text-sm font-medium">{item.label}</span>
                      </div>
                    ))}
                  </div>
                </div>

                <div className="grid grid-cols-3 gap-3">
                  <button className="flex flex-col items-center gap-2 p-4 rounded-xl border border-border hover:bg-muted transition-colors">
                    <Eye className="w-6 h-6 text-muted-foreground" />
                    <span className="text-xs">Prévisualiser</span>
                  </button>
                  <button className="flex flex-col items-center gap-2 p-4 rounded-xl border border-border hover:bg-muted transition-colors">
                    <FileText className="w-6 h-6 text-muted-foreground" />
                    <span className="text-xs">Chapitres</span>
                  </button>
                  <button className="flex flex-col items-center gap-2 p-4 rounded-xl border border-border hover:bg-muted transition-colors">
                    <ImageIcon className="w-6 h-6 text-muted-foreground" />
                    <span className="text-xs">Couverture</span>
                  </button>
                </div>

                <div className="flex gap-3 pt-4 border-t border-border">
                  <Button
                    variant="outline"
                    className="flex-1 border-destructive text-destructive hover:bg-destructive hover:text-destructive-foreground"
                    onClick={() => setShowRejectModal(true)}
                  >
                    <XCircle className="w-4 h-4" />
                    Refuser
                  </Button>
                  <Button className="flex-1" onClick={handleApprove}>
                    <CheckCircle className="w-4 h-4" />
                    Valider la publication
                  </Button>
                </div>
              </div>
            </Card>
          </div>
        </div>
      </div>

      {showRejectModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-20">
          <Card className="max-w-lg w-full">
            <div className="space-y-6">
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 rounded-xl bg-red-100 flex items-center justify-center">
                  <AlertTriangle className="w-6 h-6 text-destructive" />
                </div>
                <div>
                  <h3 className="text-xl font-semibold">Refuser la publication</h3>
                  <p className="text-sm text-muted-foreground">
                    Indiquez le motif du refus à l'auteur
                  </p>
                </div>
              </div>

              <textarea
                value={rejectReason}
                onChange={(e) => setRejectReason(e.target.value)}
                placeholder="Ex: Le résumé ne correspond pas au contenu du livre. Merci de le modifier."
                className="w-full px-4 py-3 rounded-xl bg-input-background border border-border focus:outline-none focus:ring-2 focus:ring-ring transition-all min-h-32 resize-y"
              />

              <div className="flex gap-3">
                <Button
                  variant="outline"
                  className="flex-1"
                  onClick={() => setShowRejectModal(false)}
                >
                  Annuler
                </Button>
                <Button
                  className="flex-1 bg-destructive hover:bg-destructive/90"
                  onClick={handleReject}
                  disabled={!rejectReason.trim()}
                >
                  Confirmer le refus
                </Button>
              </div>
            </div>
          </Card>
        </div>
      )}
    </div>
  );
}
