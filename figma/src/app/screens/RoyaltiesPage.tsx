import { Card } from '../components/Card';
import { TrendingUp, DollarSign, BookOpen, Eye, Download } from 'lucide-react';

interface RoyaltiesPageProps {
  onNavigate: (page: string) => void;
}

export function RoyaltiesPage({ onNavigate }: RoyaltiesPageProps) {
  const earnings = [
    { month: 'Janvier', amount: 45.2 },
    { month: 'Février', amount: 52.8 },
    { month: 'Mars', amount: 78.5 },
    { month: 'Avril', amount: 91.3 },
    { month: 'Mai', amount: 112.4 },
  ];

  const bookStats = [
    {
      id: 1,
      title: "Sang d'Encre",
      reads: 2500,
      earnings: 87.5,
      trend: '+12%',
    },
    {
      id: 2,
      title: 'Les Ombres de Minuit',
      reads: 1800,
      earnings: 63.0,
      trend: '+8%',
    },
  ];

  return (
    <div className="min-h-screen bg-background pb-20 md:pb-8">
      <div className="max-w-7xl mx-auto px-4 py-8 space-y-8">
        <div>
          <h1 className="text-4xl font-bold text-foreground">Revenus & Statistiques</h1>
          <p className="text-muted-foreground mt-2">
            Suivez vos performances et vos revenus en temps réel
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
          <Card className="bg-gradient-to-br from-primary to-purple-700 text-white border-0">
            <div className="space-y-2">
              <div className="flex items-center gap-2 text-white/80">
                <DollarSign className="w-4 h-4" />
                <p className="text-sm">Ce mois-ci</p>
              </div>
              <p className="text-4xl font-bold">112,40 €</p>
              <p className="text-sm text-white/80">+23% vs mois dernier</p>
            </div>
          </Card>

          <Card>
            <div className="space-y-2">
              <div className="flex items-center gap-2 text-muted-foreground">
                <TrendingUp className="w-4 h-4" />
                <p className="text-sm">Total des revenus</p>
              </div>
              <p className="text-3xl font-bold text-primary">380,20 €</p>
            </div>
          </Card>

          <Card>
            <div className="space-y-2">
              <div className="flex items-center gap-2 text-muted-foreground">
                <Eye className="w-4 h-4" />
                <p className="text-sm">Lectures totales</p>
              </div>
              <p className="text-3xl font-bold text-secondary">4 300</p>
            </div>
          </Card>

          <Card>
            <div className="space-y-2">
              <div className="flex items-center gap-2 text-muted-foreground">
                <BookOpen className="w-4 h-4" />
                <p className="text-sm">Livres publiés</p>
              </div>
              <p className="text-3xl font-bold text-accent">2</p>
            </div>
          </Card>
        </div>

        <Card>
          <h2 className="text-xl font-semibold mb-6">Revenus par mois</h2>
          <div className="space-y-4">
            {earnings.map((item, index) => (
              <div key={index} className="space-y-2">
                <div className="flex items-center justify-between text-sm">
                  <span className="text-muted-foreground">{item.month}</span>
                  <span className="font-semibold">{item.amount.toFixed(2)} €</span>
                </div>
                <div className="h-3 bg-muted rounded-full overflow-hidden">
                  <div
                    className="h-full bg-gradient-to-r from-primary to-purple-600 transition-all"
                    style={{ width: `${(item.amount / 150) * 100}%` }}
                  />
                </div>
              </div>
            ))}
          </div>
        </Card>

        <div>
          <h2 className="text-2xl font-semibold mb-4">Performance par livre</h2>
          <div className="space-y-4">
            {bookStats.map((book) => (
              <Card key={book.id}>
                <div className="flex items-center justify-between">
                  <div className="space-y-1">
                    <h3 className="font-semibold text-lg">{book.title}</h3>
                    <div className="flex items-center gap-4 text-sm text-muted-foreground">
                      <div className="flex items-center gap-1">
                        <Eye className="w-4 h-4" />
                        <span>{book.reads.toLocaleString()} lectures</span>
                      </div>
                      <div className="flex items-center gap-1 text-accent font-medium">
                        <TrendingUp className="w-4 h-4" />
                        <span>{book.trend}</span>
                      </div>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="text-2xl font-bold text-primary">
                      {book.earnings.toFixed(2)} €
                    </p>
                    <p className="text-sm text-muted-foreground">ce mois-ci</p>
                  </div>
                </div>
              </Card>
            ))}
          </div>
        </div>

        <Card className="bg-muted/50">
          <div className="flex items-start justify-between">
            <div>
              <h3 className="font-semibold mb-2">Paiement en attente</h3>
              <p className="text-sm text-muted-foreground mb-4">
                Votre prochain paiement sera effectué le 1er juin 2026
              </p>
              <p className="text-3xl font-bold text-primary">112,40 €</p>
            </div>
            <button className="flex items-center gap-2 px-4 py-2 rounded-xl bg-primary text-primary-foreground hover:opacity-90 transition-opacity">
              <Download className="w-4 h-4" />
              Télécharger le relevé
            </button>
          </div>
        </Card>
      </div>
    </div>
  );
}
