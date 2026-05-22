import { useState } from 'react';
import { Button } from '../components/Button';
import { Card } from '../components/Card';
import { Badge } from '../components/Badge';
import {
  ArrowLeft,
  MessageSquare,
  AlertCircle,
  Clock,
  CheckCircle,
  Zap,
  MessageCircle,
  Eye,
} from 'lucide-react';

interface BetaReadingPageProps {
  onNavigate: (page: string) => void;
}

export function BetaReadingPage({ onNavigate }: BetaReadingPageProps) {
  const [showCommentForm, setShowCommentForm] = useState(false);
  const [selectedType, setSelectedType] = useState('');
  const [comment, setComment] = useState('');
  const [selectedText, setSelectedText] = useState(
    'Elle changea d\'avis brusquement et décida de partir.'
  );

  const commentTypes = [
    { id: 'incoherence', label: 'Incohérence', icon: AlertCircle, color: 'text-red-600' },
    { id: 'rythme', label: 'Rythme lent', icon: Clock, color: 'text-orange-600' },
    { id: 'faute', label: 'Faute', icon: Eye, color: 'text-blue-600' },
    { id: 'dialogue', label: 'Dialogue', icon: MessageCircle, color: 'text-purple-600' },
    { id: 'confus', label: 'Passage confus', icon: Zap, color: 'text-yellow-600' },
  ];

  const handleSendComment = () => {
    setShowCommentForm(false);
    setComment('');
    setSelectedType('');
  };

  return (
    <div className="min-h-screen bg-background flex flex-col">
      <header className="bg-card border-b border-border px-4 py-3 sticky top-0 z-10">
        <div className="max-w-4xl mx-auto flex items-center justify-between">
          <button
            onClick={() => onNavigate('beta-tests')}
            className="flex items-center gap-2 text-muted-foreground hover:text-foreground transition-colors"
          >
            <ArrowLeft className="w-5 h-5" />
            Retour
          </button>

          <div className="text-center">
            <h2 className="font-semibold">La Nuit Rouge</h2>
            <p className="text-sm text-muted-foreground">Chapitre 2 : La découverte</p>
          </div>

          <Button size="sm" onClick={() => setShowCommentForm(true)}>
            <MessageSquare className="w-4 h-4" />
            Commenter
          </Button>
        </div>
      </header>

      <div className="flex-1 overflow-y-auto">
        <div className="max-w-4xl mx-auto px-6 py-8">
          <div className="prose prose-lg max-w-none space-y-6">
            <p className="text-foreground leading-relaxed">
              Le matin se leva lentement sur la ville endormie. Clara n'avait pas dormi de
              la nuit, trop occupée à réfléchir aux événements étranges de la veille.
            </p>

            <p className="text-foreground leading-relaxed">
              Dans la cuisine, elle prépara son café habituel, mais rien ne semblait plus
              pareil. Chaque objet, chaque son prenait une dimension nouvelle, comme si le
              monde s'était subtilement transformé.
            </p>

            <div className="relative">
              <p
                className="text-foreground leading-relaxed bg-yellow-50 border-l-4 border-yellow-400 pl-4 py-2 cursor-pointer"
                onClick={() => setShowCommentForm(true)}
              >
                {selectedText}
              </p>
              <span className="absolute -right-2 top-2 w-6 h-6 bg-yellow-400 rounded-full flex items-center justify-center text-xs font-bold text-white">
                1
              </span>
            </div>

            <p className="text-foreground leading-relaxed">
              Elle savait qu'elle ne pouvait plus rester les bras croisés. Il était temps
              d'agir, de chercher des réponses aux questions qui la hantaient depuis si
              longtemps.
            </p>

            <p className="text-foreground leading-relaxed">
              Le téléphone sonna. C'était Elias. Sa voix semblait tendue, inquiète même.
            </p>

            <p className="text-foreground leading-relaxed">
              "Clara, il faut qu'on se voie. J'ai découvert quelque chose d'important."
            </p>
          </div>
        </div>
      </div>

      {showCommentForm && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-20">
          <Card className="max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <div className="space-y-6">
              <div className="flex items-center justify-between">
                <h3 className="text-xl font-semibold">Ajouter un commentaire</h3>
                <button
                  onClick={() => setShowCommentForm(false)}
                  className="text-muted-foreground hover:text-foreground"
                >
                  ✕
                </button>
              </div>

              <div className="bg-muted/50 p-4 rounded-xl">
                <p className="text-sm font-medium mb-2">Texte sélectionné :</p>
                <p className="italic text-muted-foreground">"{selectedText}"</p>
              </div>

              <div className="space-y-3">
                <label className="text-sm font-medium">Type de retour</label>
                <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
                  {commentTypes.map((type) => {
                    const Icon = type.icon;
                    return (
                      <button
                        key={type.id}
                        onClick={() => setSelectedType(type.id)}
                        className={`flex items-center gap-2 p-3 rounded-xl border-2 transition-all ${
                          selectedType === type.id
                            ? 'border-primary bg-purple-50'
                            : 'border-border hover:border-primary/50'
                        }`}
                      >
                        <Icon className={`w-5 h-5 ${type.color}`} />
                        <span className="text-sm font-medium">{type.label}</span>
                      </button>
                    );
                  })}
                </div>
              </div>

              <div className="space-y-2">
                <label className="text-sm font-medium">Votre commentaire</label>
                <textarea
                  value={comment}
                  onChange={(e) => setComment(e.target.value)}
                  placeholder="Ce passage arrive trop vite, on ne comprend pas pourquoi elle change d'avis."
                  className="w-full px-4 py-3 rounded-xl bg-input-background border border-border focus:outline-none focus:ring-2 focus:ring-ring transition-all min-h-32 resize-y"
                />
              </div>

              <div className="flex gap-3">
                <Button
                  variant="outline"
                  className="flex-1"
                  onClick={() => setShowCommentForm(false)}
                >
                  Annuler
                </Button>
                <Button
                  className="flex-1"
                  onClick={handleSendComment}
                  disabled={!selectedType || !comment.trim()}
                >
                  <CheckCircle className="w-4 h-4" />
                  Envoyer le retour
                </Button>
              </div>
            </div>
          </Card>
        </div>
      )}

      <footer className="bg-card border-t border-border px-4 py-4">
        <div className="max-w-4xl mx-auto flex items-center justify-between">
          <span className="text-sm text-muted-foreground">Chapitre 2 sur 8</span>
          <div className="flex gap-2">
            <Button variant="outline" size="sm">
              Chapitre précédent
            </Button>
            <Button size="sm">Chapitre suivant</Button>
          </div>
        </div>
      </footer>
    </div>
  );
}
