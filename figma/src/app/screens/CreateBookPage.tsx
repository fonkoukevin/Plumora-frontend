import { useState } from 'react';
import { Button } from '../components/Button';
import { Input } from '../components/Input';
import { Card } from '../components/Card';
import { Upload, ArrowLeft } from 'lucide-react';

interface CreateBookPageProps {
  onNavigate: (page: string) => void;
}

export function CreateBookPage({ onNavigate }: CreateBookPageProps) {
  const [title, setTitle] = useState('');
  const [genre, setGenre] = useState('');
  const [summary, setSummary] = useState('');
  const [visibility, setVisibility] = useState('private');

  const handleCreate = () => {
    onNavigate('author-dashboard');
  };

  return (
    <div className="min-h-screen bg-background">
      <div className="max-w-3xl mx-auto px-4 py-8 space-y-8">
        <div className="flex items-center gap-4">
          <button
            onClick={() => onNavigate('author-dashboard')}
            className="flex items-center gap-2 text-muted-foreground hover:text-foreground transition-colors"
          >
            <ArrowLeft className="w-5 h-5" />
            Retour
          </button>
        </div>

        <div>
          <h1 className="text-4xl font-bold text-foreground">Créer un nouveau livre</h1>
          <p className="text-muted-foreground mt-2">
            Remplissez les informations pour commencer votre nouveau projet
          </p>
        </div>

        <Card className="space-y-6">
          <Input
            id="title"
            label="Titre du livre"
            placeholder="Ex: La Nuit Rouge"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
          />

          <div className="flex flex-col gap-2">
            <label htmlFor="genre" className="text-sm text-foreground">
              Genre
            </label>
            <select
              id="genre"
              value={genre}
              onChange={(e) => setGenre(e.target.value)}
              className="w-full px-4 py-2.5 rounded-xl bg-input-background border border-border focus:outline-none focus:ring-2 focus:ring-ring transition-all"
            >
              <option value="">Sélectionner un genre</option>
              <option value="fantasy">Fantasy</option>
              <option value="romance">Romance</option>
              <option value="thriller">Thriller</option>
              <option value="science-fiction">Science-Fiction</option>
              <option value="mystery">Mystère</option>
              <option value="horror">Horreur</option>
              <option value="contemporary">Contemporain</option>
            </select>
          </div>

          <div className="flex flex-col gap-2">
            <label htmlFor="summary" className="text-sm text-foreground">
              Résumé court
            </label>
            <textarea
              id="summary"
              value={summary}
              onChange={(e) => setSummary(e.target.value)}
              placeholder="Décrivez votre livre en quelques lignes..."
              className="w-full px-4 py-2.5 rounded-xl bg-input-background border border-border focus:outline-none focus:ring-2 focus:ring-ring transition-all min-h-32 resize-y"
            />
          </div>

          <div className="flex flex-col gap-2">
            <label className="text-sm text-foreground">Visibilité</label>
            <div className="space-y-2">
              <label className="flex items-center gap-3 p-4 rounded-xl border border-border cursor-pointer hover:bg-muted transition-colors">
                <input
                  type="radio"
                  name="visibility"
                  value="private"
                  checked={visibility === 'private'}
                  onChange={(e) => setVisibility(e.target.value)}
                  className="w-4 h-4 text-primary"
                />
                <div>
                  <p className="font-medium">Privé</p>
                  <p className="text-sm text-muted-foreground">
                    Visible uniquement par vous
                  </p>
                </div>
              </label>

              <label className="flex items-center gap-3 p-4 rounded-xl border border-border cursor-pointer hover:bg-muted transition-colors">
                <input
                  type="radio"
                  name="visibility"
                  value="beta"
                  checked={visibility === 'beta'}
                  onChange={(e) => setVisibility(e.target.value)}
                  className="w-4 h-4 text-primary"
                />
                <div>
                  <p className="font-medium">Bêta-test uniquement</p>
                  <p className="text-sm text-muted-foreground">
                    Accessible aux bêta-testeurs sélectionnés
                  </p>
                </div>
              </label>

              <label className="flex items-center gap-3 p-4 rounded-xl border border-border cursor-pointer hover:bg-muted transition-colors">
                <input
                  type="radio"
                  name="visibility"
                  value="public"
                  checked={visibility === 'public'}
                  onChange={(e) => setVisibility(e.target.value)}
                  className="w-4 h-4 text-primary"
                />
                <div>
                  <p className="font-medium">Publication interne</p>
                  <p className="text-sm text-muted-foreground">
                    Visible par tous les utilisateurs de Plumora
                  </p>
                </div>
              </label>
            </div>
          </div>

          <div className="flex flex-col gap-2">
            <label className="text-sm text-foreground">Couverture du livre</label>
            <div className="border-2 border-dashed border-border rounded-xl p-8 text-center hover:border-primary transition-colors cursor-pointer">
              <div className="flex flex-col items-center gap-3">
                <div className="w-16 h-16 rounded-xl bg-muted flex items-center justify-center">
                  <Upload className="w-8 h-8 text-muted-foreground" />
                </div>
                <div>
                  <p className="font-medium">Importer une couverture</p>
                  <p className="text-sm text-muted-foreground">
                    PNG, JPG jusqu'à 5MB
                  </p>
                </div>
              </div>
            </div>
          </div>

          <div className="flex gap-4 pt-4">
            <Button
              variant="outline"
              className="flex-1"
              onClick={() => onNavigate('author-dashboard')}
            >
              Annuler
            </Button>
            <Button className="flex-1" onClick={handleCreate}>
              Créer le livre
            </Button>
          </div>
        </Card>
      </div>
    </div>
  );
}
