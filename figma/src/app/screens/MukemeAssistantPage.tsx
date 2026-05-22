import { useState } from 'react';
import { Card } from '../components/Card';
import { Button } from '../components/Button';
import { Badge } from '../components/Badge';
import {
  ArrowLeft,
  Sparkles,
  RefreshCw,
  Wand2,
  Heart,
  Repeat,
  MessageCircle,
  Check,
  X,
  Edit,
} from 'lucide-react';

interface MukemeAssistantPageProps {
  onNavigate: (page: string) => void;
}

export function MukemeAssistantPage({ onNavigate }: MukemeAssistantPageProps) {
  const [selectedText] = useState(
    'Elle était très triste et elle marchait très lentement dans la rue.'
  );
  const [showSuggestion, setShowSuggestion] = useState(false);
  const [selectedAction, setSelectedAction] = useState('');

  const actions = [
    { id: 'reformulate', label: 'Reformuler', icon: RefreshCw },
    { id: 'improve', label: 'Améliorer le style', icon: Wand2 },
    { id: 'emotional', label: 'Rendre plus émotionnel', icon: Heart },
    { id: 'repetitions', label: 'Corriger les répétitions', icon: Repeat },
    { id: 'dialogue', label: 'Rendre le dialogue plus naturel', icon: MessageCircle },
  ];

  const suggestion =
    'Elle avançait lentement dans la rue, le cœur lourd, comme si chaque pas lui coûtait.';

  const handleAction = (actionId: string) => {
    setSelectedAction(actionId);
    setShowSuggestion(true);
  };

  return (
    <div className="h-screen bg-background flex flex-col">
      <header className="bg-card border-b border-border px-4 py-4">
        <div className="max-w-6xl mx-auto flex items-center justify-between">
          <button
            onClick={() => onNavigate('editor')}
            className="flex items-center gap-2 text-muted-foreground hover:text-foreground transition-colors"
          >
            <ArrowLeft className="w-5 h-5" />
            Retour à l'éditeur
          </button>

          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-gradient-to-br from-primary to-purple-600 flex items-center justify-center">
              <Sparkles className="w-6 h-6 text-white" />
            </div>
            <div>
              <h2 className="font-semibold">Mukeme</h2>
              <p className="text-xs text-muted-foreground">Assistant d'écriture</p>
            </div>
          </div>

          <div className="w-24" />
        </div>
      </header>

      <div className="flex-1 overflow-y-auto">
        <div className="max-w-6xl mx-auto px-4 py-8 space-y-8">
          <div className="text-center space-y-2">
            <h1 className="text-3xl font-bold">Améliore ton texte avec Mukeme</h1>
            <p className="text-muted-foreground">
              Sélectionne une action et laisse Mukeme te proposer des améliorations
            </p>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
            <div className="space-y-6">
              <Card>
                <div className="space-y-4">
                  <div className="flex items-center gap-2">
                    <Badge variant="beta">Texte sélectionné</Badge>
                  </div>
                  <div className="bg-yellow-50 border-l-4 border-yellow-400 p-4 rounded-lg">
                    <p className="leading-relaxed">{selectedText}</p>
                  </div>
                </div>
              </Card>

              <Card>
                <div className="space-y-4">
                  <h3 className="font-semibold">Actions disponibles</h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                    {actions.map((action) => {
                      const Icon = action.icon;
                      return (
                        <button
                          key={action.id}
                          onClick={() => handleAction(action.id)}
                          className={`flex items-center gap-3 p-4 rounded-xl border-2 transition-all ${
                            selectedAction === action.id
                              ? 'border-primary bg-purple-50'
                              : 'border-border hover:border-primary/50'
                          }`}
                        >
                          <Icon className="w-5 h-5 text-primary" />
                          <span className="text-sm font-medium">{action.label}</span>
                        </button>
                      );
                    })}
                  </div>
                </div>
              </Card>

              <Card className="bg-blue-50 border-blue-200">
                <div className="flex items-start gap-3">
                  <Sparkles className="w-6 h-6 text-primary shrink-0 mt-1" />
                  <div className="space-y-2">
                    <h4 className="font-semibold">L'auteur garde le contrôle</h4>
                    <p className="text-sm text-muted-foreground">
                      Mukeme est une aide à l'écriture, pas un remplacement. Vous pouvez
                      accepter, modifier ou ignorer toutes les suggestions.
                    </p>
                  </div>
                </div>
              </Card>
            </div>

            <div className="space-y-6">
              {showSuggestion && (
                <>
                  <Card>
                    <div className="space-y-4">
                      <div className="flex items-center gap-2">
                        <Sparkles className="w-5 h-5 text-primary" />
                        <h3 className="font-semibold">Suggestion de Mukeme</h3>
                      </div>

                      <div className="bg-purple-50 border-l-4 border-primary p-4 rounded-lg">
                        <p className="leading-relaxed">{suggestion}</p>
                      </div>

                      <div className="flex gap-3">
                        <Button className="flex-1" onClick={() => onNavigate('editor')}>
                          <Check className="w-4 h-4" />
                          Accepter
                        </Button>
                        <Button variant="outline" className="flex-1">
                          <Edit className="w-4 h-4" />
                          Modifier
                        </Button>
                        <Button variant="ghost">
                          <X className="w-4 h-4" />
                          Ignorer
                        </Button>
                      </div>
                    </div>
                  </Card>

                  <Card>
                    <div className="space-y-4">
                      <h4 className="font-semibold">Améliorations apportées</h4>
                      <ul className="space-y-2 text-sm">
                        <li className="flex items-start gap-2">
                          <Check className="w-4 h-4 text-accent mt-0.5 shrink-0" />
                          <span>Suppression de la répétition "très"</span>
                        </li>
                        <li className="flex items-start gap-2">
                          <Check className="w-4 h-4 text-accent mt-0.5 shrink-0" />
                          <span>Ajout d'une métaphore pour renforcer l'émotion</span>
                        </li>
                        <li className="flex items-start gap-2">
                          <Check className="w-4 h-4 text-accent mt-0.5 shrink-0" />
                          <span>Rythme de la phrase amélioré</span>
                        </li>
                        <li className="flex items-start gap-2">
                          <Check className="w-4 h-4 text-accent mt-0.5 shrink-0" />
                          <span>Style plus littéraire et évocateur</span>
                        </li>
                      </ul>
                    </div>
                  </Card>

                  <Button variant="outline" className="w-full" onClick={() => setShowSuggestion(false)}>
                    <RefreshCw className="w-4 h-4" />
                    Générer une autre suggestion
                  </Button>
                </>
              )}

              {!showSuggestion && (
                <Card className="h-full flex items-center justify-center min-h-[400px]">
                  <div className="text-center space-y-4 p-8">
                    <div className="w-20 h-20 mx-auto rounded-full bg-muted flex items-center justify-center">
                      <Sparkles className="w-10 h-10 text-muted-foreground" />
                    </div>
                    <div>
                      <h3 className="font-semibold mb-2">
                        Choisis une action
                      </h3>
                      <p className="text-sm text-muted-foreground">
                        Sélectionne une action dans la liste pour voir la suggestion de
                        Mukeme
                      </p>
                    </div>
                  </div>
                </Card>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
