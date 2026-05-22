import { Button } from '../components/Button';
import { Card } from '../components/Card';
import { Feather, BookOpen, TestTube } from 'lucide-react';
import { useState } from 'react';

interface RoleSelectionPageProps {
  onNavigate: (page: string) => void;
}

export function RoleSelectionPage({ onNavigate }: RoleSelectionPageProps) {
  const [selectedRoles, setSelectedRoles] = useState<string[]>([]);

  const toggleRole = (role: string) => {
    setSelectedRoles((prev) =>
      prev.includes(role) ? prev.filter((r) => r !== role) : [...prev, role]
    );
  };

  const handleContinue = () => {
    onNavigate('home');
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-background px-4">
      <div className="w-full max-w-3xl space-y-8">
        <div className="text-center space-y-4">
          <h1 className="text-4xl font-bold text-foreground">
            Comment veux-tu utiliser Plumora ?
          </h1>
          <p className="text-muted-foreground">
            Sélectionne un ou plusieurs rôles pour personnaliser ton expérience
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <Card
            hover
            onClick={() => toggleRole('author')}
            className={`cursor-pointer transition-all ${
              selectedRoles.includes('author')
                ? 'border-primary border-2 bg-purple-50'
                : ''
            }`}
          >
            <div className="flex flex-col items-center text-center space-y-4">
              <div className="w-16 h-16 rounded-2xl bg-purple-100 flex items-center justify-center">
                <Feather className="w-8 h-8 text-primary" />
              </div>
              <h3 className="font-semibold">Auteur</h3>
              <p className="text-sm text-muted-foreground">
                Écrire, organiser et publier mes livres
              </p>
            </div>
          </Card>

          <Card
            hover
            onClick={() => toggleRole('reader')}
            className={`cursor-pointer transition-all ${
              selectedRoles.includes('reader')
                ? 'border-primary border-2 bg-purple-50'
                : ''
            }`}
          >
            <div className="flex flex-col items-center text-center space-y-4">
              <div className="w-16 h-16 rounded-2xl bg-amber-100 flex items-center justify-center">
                <BookOpen className="w-8 h-8 text-secondary" />
              </div>
              <h3 className="font-semibold">Lecteur</h3>
              <p className="text-sm text-muted-foreground">
                Découvrir, lire et sauvegarder des livres
              </p>
            </div>
          </Card>

          <Card
            hover
            onClick={() => toggleRole('beta')}
            className={`cursor-pointer transition-all ${
              selectedRoles.includes('beta')
                ? 'border-primary border-2 bg-purple-50'
                : ''
            }`}
          >
            <div className="flex flex-col items-center text-center space-y-4">
              <div className="w-16 h-16 rounded-2xl bg-green-100 flex items-center justify-center">
                <TestTube className="w-8 h-8 text-accent" />
              </div>
              <h3 className="font-semibold">Bêta-testeur</h3>
              <p className="text-sm text-muted-foreground">
                Lire des manuscrits avant publication et donner mon avis
              </p>
            </div>
          </Card>
        </div>

        <div className="space-y-4">
          <Button
            className="w-full"
            size="lg"
            onClick={handleContinue}
            disabled={selectedRoles.length === 0}
          >
            Continuer
          </Button>
          <p className="text-sm text-center text-muted-foreground">
            Tu pourras modifier tes rôles plus tard dans ton profil
          </p>
        </div>
      </div>
    </div>
  );
}
