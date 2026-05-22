import { useState } from 'react';
import { Card } from '../components/Card';
import { Button } from '../components/Button';
import { Badge } from '../components/Badge';
import {
  ArrowLeft,
  ChevronDown,
  Save,
  Sparkles,
  Check,
  X,
  RefreshCw,
  Wand2,
  Heart,
  Repeat,
} from 'lucide-react';

interface MobileEditorPageProps {
  onNavigate: (page: string) => void;
}

export function MobileEditorPage({ onNavigate }: MobileEditorPageProps) {
  const [activeChapter, setActiveChapter] = useState('Chapitre 3');
  const [showMukeme, setShowMukeme] = useState(false);
  const [showSuggestion, setShowSuggestion] = useState(false);
  const [content, setContent] = useState(
    `Elle était très triste et elle marchait très lentement dans la rue.\n\nLa nuit tombait sur la ville, et Clara sentait le poids de sa décision.\n\nElle savait qu'elle ne pourrait plus revenir en arrière.`
  );

  const chapters = [
    'Prologue',
    'Chapitre 1',
    'Chapitre 2',
    'Chapitre 3',
    'Chapitre 4',
  ];

  const mukemeActions = [
    { id: 'reformulate', label: 'Reformuler', icon: RefreshCw },
    { id: 'improve', label: 'Améliorer le style', icon: Wand2 },
    { id: 'emotional', label: 'Rendre plus émotionnel', icon: Heart },
    { id: 'repetitions', label: 'Corriger les répétitions', icon: Repeat },
  ];

  const suggestion = 'Elle avançait lentement dans la rue, le cœur lourd, comme si chaque pas lui coûtait.';

  const handleMukemeAction = (actionId: string) => {
    setShowSuggestion(true);
  };

  const handleAccept = () => {
    setContent(content.replace('Elle était très triste et elle marchait très lentement dans la rue.', suggestion));
    setShowMukeme(false);
    setShowSuggestion(false);
  };

  return (
    <div className="min-h-screen bg-background flex flex-col">
      {/* Header */}
      <header className="bg-card border-b border-border px-4 py-3 sticky top-0 z-10">
        <div className="flex items-center justify-between">
          <button
            onClick={() => onNavigate('write')}
            className="flex items-center gap-2 text-muted-foreground"
          >
            <ArrowLeft className="w-5 h-5" />
            <span className="text-sm">Retour</span>
          </button>

          <div className="flex items-center gap-2">
            <button className="flex items-center gap-1 px-3 py-1.5 rounded-lg hover:bg-muted">
              <span className="text-sm font-medium">{activeChapter}</span>
              <ChevronDown className="w-4 h-4" />
            </button>
          </div>

          <button className="p-2 rounded-lg hover:bg-muted">
            <Save className="w-5 h-5 text-primary" />
          </button>
        </div>

        <div className="mt-3">
          <h2 className="font-bold text-lg">La Nuit Rouge</h2>
          <p className="text-xs text-muted-foreground">Chapitre 3 : Le départ</p>
        </div>
      </header>

      {/* Editor */}
      <div className="flex-1 overflow-y-auto p-4">
        <textarea
          value={content}
          onChange={(e) => setContent(e.target.value)}
          className="w-full min-h-[400px] bg-transparent border-none focus:outline-none resize-none leading-relaxed text-foreground"
          placeholder="Commencez à écrire..."
          style={{ fontSize: '16px', lineHeight: '1.8' }}
        />
      </div>

      {/* Bottom Actions */}
      <div className="bg-card border-t border-border p-4 space-y-3">
        <div className="flex items-center justify-between text-xs text-muted-foreground">
          <span>{content.split(' ').length} mots</span>
          <span>Sauvegardé automatiquement</span>
        </div>

        <Button
          className="w-full"
          size="lg"
          onClick={() => setShowMukeme(true)}
        >
          <Sparkles className="w-5 h-5" />
          Demander à Mukeme
        </Button>
      </div>

      {/* Mukeme Modal */}
      {showMukeme && (
        <div className="fixed inset-0 bg-black/50 z-50 flex flex-col">
          {/* Modal Header */}
          <div className="bg-gradient-to-r from-primary to-purple-700 px-4 py-4 text-white">
            <div className="flex items-center justify-between mb-3">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-full bg-white/20 backdrop-blur-sm flex items-center justify-center">
                  <Sparkles className="w-6 h-6" />
                </div>
                <div>
                  <h3 className="font-bold">Mukeme</h3>
                  <p className="text-xs text-white/80">Assistant d'écriture</p>
                </div>
              </div>
              <button
                onClick={() => {
                  setShowMukeme(false);
                  setShowSuggestion(false);
                }}
                className="p-2 hover:bg-white/20 rounded-lg"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {!showSuggestion && (
              <p className="text-sm text-white/90">Que veux-tu faire ?</p>
            )}
          </div>

          {/* Modal Content */}
          <div className="flex-1 bg-background overflow-y-auto">
            {!showSuggestion ? (
              <div className="p-4 space-y-3">
                {mukemeActions.map((action) => {
                  const Icon = action.icon;
                  return (
                    <button
                      key={action.id}
                      onClick={() => handleMukemeAction(action.id)}
                      className="w-full flex items-center gap-4 p-4 rounded-xl bg-card border-2 border-border hover:border-primary transition-all"
                    >
                      <div className="w-12 h-12 rounded-xl bg-purple-100 flex items-center justify-center">
                        <Icon className="w-6 h-6 text-primary" />
                      </div>
                      <span className="font-medium">{action.label}</span>
                    </button>
                  );
                })}
              </div>
            ) : (
              <div className="p-4 space-y-4">
                <Card className="bg-yellow-50 border-yellow-200">
                  <div className="space-y-2">
                    <p className="text-xs font-medium text-muted-foreground">Texte original :</p>
                    <p className="text-sm leading-relaxed">
                      Elle était très triste et elle marchait très lentement dans la rue.
                    </p>
                  </div>
                </Card>

                <Card className="bg-purple-50 border-primary">
                  <div className="space-y-3">
                    <div className="flex items-center gap-2">
                      <Sparkles className="w-5 h-5 text-primary" />
                      <p className="text-xs font-semibold text-primary">Suggestion de Mukeme</p>
                    </div>
                    <p className="text-sm leading-relaxed font-medium">
                      {suggestion}
                    </p>
                  </div>
                </Card>

                <Card className="bg-muted/30">
                  <div className="space-y-2">
                    <p className="text-xs font-semibold">Améliorations :</p>
                    <ul className="space-y-1.5 text-xs text-muted-foreground">
                      <li className="flex items-start gap-2">
                        <Check className="w-3.5 h-3.5 text-accent mt-0.5 shrink-0" />
                        <span>Suppression de la répétition "très"</span>
                      </li>
                      <li className="flex items-start gap-2">
                        <Check className="w-3.5 h-3.5 text-accent mt-0.5 shrink-0" />
                        <span>Ajout d'une métaphore pour l'émotion</span>
                      </li>
                      <li className="flex items-start gap-2">
                        <Check className="w-3.5 h-3.5 text-accent mt-0.5 shrink-0" />
                        <span>Style plus littéraire</span>
                      </li>
                    </ul>
                  </div>
                </Card>

                <div className="flex gap-3 pt-2">
                  <Button
                    variant="outline"
                    className="flex-1"
                    onClick={() => setShowSuggestion(false)}
                  >
                    <X className="w-4 h-4" />
                    Ignorer
                  </Button>
                  <Button
                    className="flex-1"
                    onClick={handleAccept}
                  >
                    <Check className="w-4 h-4" />
                    Accepter
                  </Button>
                </div>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
