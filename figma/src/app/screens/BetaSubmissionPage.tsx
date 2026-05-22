import { useState } from 'react';
import { Card } from '../components/Card';
import { Button } from '../components/Button';
import { Input } from '../components/Input';
import { ArrowLeft, Users, Link as LinkIcon, Send, CheckCircle } from 'lucide-react';

interface BetaSubmissionPageProps {
  onNavigate: (page: string) => void;
}

export function BetaSubmissionPage({ onNavigate }: BetaSubmissionPageProps) {
  const [selectedBetas, setSelectedBetas] = useState<string[]>(['sarah', 'marc']);
  const [instructions, setInstructions] = useState('');
  const [selectedChapters, setSelectedChapters] = useState<string[]>(['ch1', 'ch2', 'ch3']);

  const betaTesters = [
    { id: 'sarah', name: 'Sarah Dubois', email: 'sarah@email.com', books: 12 },
    { id: 'marc', name: 'Marc Lambert', email: 'marc@email.com', books: 8 },
    { id: 'julie', name: 'Julie Martin', email: 'julie@email.com', books: 15 },
    { id: 'thomas', name: 'Thomas Petit', email: 'thomas@email.com', books: 6 },
  ];

  const chapters = [
    { id: 'ch1', title: 'Chapitre 1 : Le début' },
    { id: 'ch2', title: 'Chapitre 2 : La découverte' },
    { id: 'ch3', title: 'Chapitre 3 : Le départ' },
    { id: 'ch4', title: 'Chapitre 4 : La confrontation' },
  ];

  const toggleBeta = (id: string) => {
    setSelectedBetas((prev) =>
      prev.includes(id) ? prev.filter((b) => b !== id) : [...prev, id]
    );
  };

  const toggleChapter = (id: string) => {
    setSelectedChapters((prev) =>
      prev.includes(id) ? prev.filter((c) => c !== id) : [...prev, id]
    );
  };

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
          <h1 className="text-4xl font-bold text-foreground">Envoyer en bêta-test</h1>
          <p className="text-muted-foreground mt-2">La Nuit Rouge</p>
        </div>

        <Card>
          <div className="space-y-4">
            <div className="flex items-center gap-3">
              <Users className="w-6 h-6 text-primary" />
              <h2 className="text-xl font-semibold">Choisir les bêta-testeurs</h2>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              {betaTesters.map((beta) => (
                <label
                  key={beta.id}
                  className={`flex items-center gap-3 p-4 rounded-xl border-2 cursor-pointer transition-all ${
                    selectedBetas.includes(beta.id)
                      ? 'border-primary bg-purple-50'
                      : 'border-border hover:border-primary/50'
                  }`}
                >
                  <input
                    type="checkbox"
                    checked={selectedBetas.includes(beta.id)}
                    onChange={() => toggleBeta(beta.id)}
                    className="w-5 h-5 text-primary rounded"
                  />
                  <div className="flex-1">
                    <p className="font-medium">{beta.name}</p>
                    <p className="text-sm text-muted-foreground">{beta.books} livres testés</p>
                  </div>
                </label>
              ))}
            </div>

            <p className="text-sm text-muted-foreground">
              {selectedBetas.length} bêta-testeur(s) sélectionné(s)
            </p>
          </div>
        </Card>

        <Card>
          <div className="space-y-4">
            <div className="flex items-center gap-3">
              <CheckCircle className="w-6 h-6 text-primary" />
              <h2 className="text-xl font-semibold">Chapitres à partager</h2>
            </div>

            <div className="space-y-2">
              {chapters.map((chapter) => (
                <label
                  key={chapter.id}
                  className={`flex items-center gap-3 p-3 rounded-xl border cursor-pointer transition-all ${
                    selectedChapters.includes(chapter.id)
                      ? 'border-primary bg-purple-50'
                      : 'border-border hover:border-primary/50'
                  }`}
                >
                  <input
                    type="checkbox"
                    checked={selectedChapters.includes(chapter.id)}
                    onChange={() => toggleChapter(chapter.id)}
                    className="w-5 h-5 text-primary rounded"
                  />
                  <span className="font-medium">{chapter.title}</span>
                </label>
              ))}
            </div>
          </div>
        </Card>

        <Card>
          <div className="space-y-4">
            <h2 className="text-xl font-semibold">Consignes pour les bêta-testeurs</h2>
            <textarea
              value={instructions}
              onChange={(e) => setInstructions(e.target.value)}
              placeholder="Ex: Merci de vous concentrer sur le rythme et la cohérence des personnages. N'hésitez pas à me signaler les passages confus."
              className="w-full px-4 py-3 rounded-xl bg-input-background border border-border focus:outline-none focus:ring-2 focus:ring-ring transition-all min-h-32 resize-y"
            />
          </div>
        </Card>

        <Card className="bg-blue-50 border-blue-200">
          <div className="space-y-3">
            <div className="flex items-center gap-3">
              <LinkIcon className="w-6 h-6 text-blue-600" />
              <h2 className="text-xl font-semibold">Lien privé d'invitation</h2>
            </div>
            <div className="flex gap-2">
              <input
                type="text"
                value="https://plumora.app/beta/nuit-rouge-a8f3k2"
                readOnly
                className="flex-1 px-4 py-2 rounded-xl bg-white border border-blue-200"
              />
              <Button variant="outline">Copier</Button>
            </div>
            <p className="text-sm text-muted-foreground">
              Ce lien permet aux bêta-testeurs d'accéder directement au manuscrit
            </p>
          </div>
        </Card>

        <div className="flex gap-4">
          <Button
            variant="outline"
            className="flex-1"
            onClick={() => onNavigate('author-dashboard')}
          >
            Annuler
          </Button>
          <Button className="flex-1" disabled={selectedBetas.length === 0}>
            <Send className="w-4 h-4" />
            Envoyer aux bêta-testeurs
          </Button>
        </div>
      </div>
    </div>
  );
}
