import { useState } from 'react';
import { Card } from '../components/Card';
import { Button } from '../components/Button';
import { Input } from '../components/Input';
import {
  ArrowLeft,
  CheckCircle,
  Circle,
  Upload,
  DollarSign,
  Send,
} from 'lucide-react';

interface PublicationPrepPageProps {
  onNavigate: (page: string) => void;
}

export function PublicationPrepPage({ onNavigate }: PublicationPrepPageProps) {
  const [pricingModel, setPricingModel] = useState('royalties');
  const [price, setPrice] = useState('');
  const [category, setCategory] = useState('thriller');

  const checklist = [
    { id: 'title', label: 'Titre renseigné', completed: true },
    { id: 'summary', label: 'Résumé renseigné', completed: true },
    { id: 'cover', label: 'Couverture ajoutée', completed: true },
    { id: 'chapters', label: 'Tous les chapitres complétés', completed: true },
    { id: 'beta', label: 'Retours bêta traités', completed: true },
    { id: 'pricing', label: 'Prix / modèle de rémunération défini', completed: false },
    { id: 'category', label: 'Catégorie sélectionnée', completed: true },
  ];

  const completedCount = checklist.filter((item) => item.completed).length;
  const progress = (completedCount / checklist.length) * 100;

  return (
    <div className="min-h-screen bg-background pb-8">
      <div className="max-w-4xl mx-auto px-4 py-8 space-y-8">
        <button
          onClick={() => onNavigate('author-dashboard')}
          className="flex items-center gap-2 text-muted-foreground hover:text-foreground transition-colors"
        >
          <ArrowLeft className="w-5 h-5" />
          Retour
        </button>

        <div>
          <h1 className="text-4xl font-bold text-foreground">Préparer la publication</h1>
          <p className="text-muted-foreground mt-2">La Nuit Rouge</p>
        </div>

        <Card>
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <h2 className="text-xl font-semibold">Progression</h2>
              <span className="text-2xl font-bold text-primary">{Math.round(progress)}%</span>
            </div>
            <div className="h-3 bg-muted rounded-full overflow-hidden">
              <div
                className="h-full bg-primary transition-all"
                style={{ width: `${progress}%` }}
              />
            </div>
          </div>
        </Card>

        <Card>
          <div className="space-y-4">
            <h2 className="text-xl font-semibold">Checklist de publication</h2>
            <div className="space-y-3">
              {checklist.map((item) => (
                <div
                  key={item.id}
                  className={`flex items-center gap-3 p-3 rounded-xl ${
                    item.completed ? 'bg-green-50' : 'bg-muted/50'
                  }`}
                >
                  {item.completed ? (
                    <CheckCircle className="w-5 h-5 text-accent shrink-0" />
                  ) : (
                    <Circle className="w-5 h-5 text-muted-foreground shrink-0" />
                  )}
                  <span
                    className={
                      item.completed
                        ? 'text-foreground font-medium'
                        : 'text-muted-foreground'
                    }
                  >
                    {item.label}
                  </span>
                </div>
              ))}
            </div>
          </div>
        </Card>

        <Card>
          <div className="space-y-6">
            <div className="flex items-center gap-3">
              <DollarSign className="w-6 h-6 text-primary" />
              <h2 className="text-xl font-semibold">Modèle de publication</h2>
            </div>

            <div className="space-y-3">
              <label className="flex items-start gap-3 p-4 rounded-xl border-2 cursor-pointer transition-all hover:border-primary/50">
                <input
                  type="radio"
                  name="pricing"
                  value="free"
                  checked={pricingModel === 'free'}
                  onChange={(e) => setPricingModel(e.target.value)}
                  className="w-5 h-5 text-primary mt-0.5"
                />
                <div>
                  <p className="font-medium">Gratuit</p>
                  <p className="text-sm text-muted-foreground">
                    Votre livre sera accessible gratuitement à tous les lecteurs
                  </p>
                </div>
              </label>

              <label className="flex items-start gap-3 p-4 rounded-xl border-2 cursor-pointer transition-all hover:border-primary/50">
                <input
                  type="radio"
                  name="pricing"
                  value="paid"
                  checked={pricingModel === 'paid'}
                  onChange={(e) => setPricingModel(e.target.value)}
                  className="w-5 h-5 text-primary mt-0.5"
                />
                <div className="flex-1">
                  <p className="font-medium">Payant</p>
                  <p className="text-sm text-muted-foreground mb-3">
                    Définissez un prix fixe pour votre livre
                  </p>
                  {pricingModel === 'paid' && (
                    <Input
                      type="number"
                      placeholder="Prix en €"
                      value={price}
                      onChange={(e) => setPrice(e.target.value)}
                    />
                  )}
                </div>
              </label>

              <label className="flex items-start gap-3 p-4 rounded-xl border-2 border-primary bg-purple-50 cursor-pointer">
                <input
                  type="radio"
                  name="pricing"
                  value="royalties"
                  checked={pricingModel === 'royalties'}
                  onChange={(e) => setPricingModel(e.target.value)}
                  className="w-5 h-5 text-primary mt-0.5"
                />
                <div>
                  <p className="font-medium">Lecture avec royalties internes</p>
                  <p className="text-sm text-muted-foreground">
                    Vous percevez des royalties en fonction du nombre de lectures (recommandé)
                  </p>
                </div>
              </label>
            </div>
          </div>
        </Card>

        <Card>
          <div className="space-y-4">
            <h2 className="text-xl font-semibold">Catégorie</h2>
            <select
              value={category}
              onChange={(e) => setCategory(e.target.value)}
              className="w-full px-4 py-3 rounded-xl bg-input-background border border-border focus:outline-none focus:ring-2 focus:ring-ring transition-all"
            >
              <option value="thriller">Thriller</option>
              <option value="romance">Romance</option>
              <option value="fantasy">Fantasy</option>
              <option value="science-fiction">Science-Fiction</option>
              <option value="mystery">Mystère</option>
              <option value="horror">Horreur</option>
              <option value="contemporary">Contemporain</option>
            </select>
          </div>
        </Card>

        <div className="flex gap-4">
          <Button
            variant="outline"
            className="flex-1"
            onClick={() => onNavigate('author-dashboard')}
          >
            Sauvegarder et continuer plus tard
          </Button>
          <Button
            className="flex-1"
            disabled={progress < 100}
            onClick={() => onNavigate('author-dashboard')}
          >
            <Send className="w-4 h-4" />
            Soumettre à validation
          </Button>
        </div>

        {progress < 100 && (
          <p className="text-sm text-center text-muted-foreground">
            Complétez tous les éléments de la checklist pour soumettre votre livre
          </p>
        )}
      </div>
    </div>
  );
}
