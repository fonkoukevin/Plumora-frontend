import { useState } from 'react';
import { Card } from '../components/Card';
import { Badge } from '../components/Badge';
import { Button } from '../components/Button';
import {
  ArrowLeft,
  Filter,
  AlertCircle,
  Clock,
  MessageCircle,
  Eye,
  Zap,
  CheckCircle,
  ExternalLink,
} from 'lucide-react';

interface BetaFeedbackPageProps {
  onNavigate: (page: string) => void;
}

export function BetaFeedbackPage({ onNavigate }: BetaFeedbackPageProps) {
  const [activeFilter, setActiveFilter] = useState('all');

  const summary = [
    { type: 'Rythme', count: 4, color: 'bg-orange-100 text-orange-700' },
    { type: 'Personnage', count: 3, color: 'bg-blue-100 text-blue-700' },
    { type: 'Incohérence', count: 2, color: 'bg-red-100 text-red-700' },
    { type: 'Style', count: 3, color: 'bg-purple-100 text-purple-700' },
  ];

  const feedbacks = [
    {
      id: 1,
      chapter: 'Chapitre 3',
      type: 'Incohérence',
      priority: 'high',
      beta: 'Sarah Dubois',
      text: 'Ce passage arrive trop vite, on ne comprend pas pourquoi elle change d\'avis.',
      excerpt: 'Elle changea d\'avis brusquement...',
      status: 'pending',
      icon: AlertCircle,
      color: 'text-red-600',
    },
    {
      id: 2,
      chapter: 'Chapitre 2',
      type: 'Rythme lent',
      priority: 'medium',
      beta: 'Marc Lambert',
      text: 'La description de la forêt est trop longue, ça ralentit l\'action.',
      excerpt: 'La forêt s\'étendait devant...',
      status: 'pending',
      icon: Clock,
      color: 'text-orange-600',
    },
    {
      id: 3,
      chapter: 'Chapitre 4',
      type: 'Dialogue',
      priority: 'low',
      beta: 'Julie Martin',
      text: 'Le dialogue entre Clara et Elias manque de naturel.',
      excerpt: '"Nous devons partir maintenant"...',
      status: 'pending',
      icon: MessageCircle,
      color: 'text-purple-600',
    },
    {
      id: 4,
      chapter: 'Chapitre 1',
      type: 'Passage confus',
      priority: 'high',
      beta: 'Sarah Dubois',
      text: 'Je ne comprends pas la relation entre Clara et son père.',
      excerpt: 'Son père avait toujours été...',
      status: 'pending',
      icon: Zap,
      color: 'text-yellow-600',
    },
  ];

  const filters = ['all', 'Incohérence', 'Rythme', 'Dialogue', 'Style'];

  return (
    <div className="min-h-screen bg-background pb-8">
      <div className="max-w-6xl mx-auto px-4 py-8 space-y-8">
        <button
          onClick={() => onNavigate('author-dashboard')}
          className="flex items-center gap-2 text-muted-foreground hover:text-foreground transition-colors"
        >
          <ArrowLeft className="w-5 h-5" />
          Retour
        </button>

        <div>
          <h1 className="text-4xl font-bold text-foreground">Retours bêta</h1>
          <p className="text-muted-foreground mt-2">La Nuit Rouge - 12 commentaires reçus</p>
        </div>

        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {summary.map((item, index) => (
            <Card key={index}>
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-muted-foreground">{item.type}</p>
                  <p className="text-2xl font-bold text-primary">{item.count}</p>
                </div>
                <div className={`w-12 h-12 rounded-xl ${item.color} flex items-center justify-center text-xl font-bold`}>
                  {item.count}
                </div>
              </div>
            </Card>
          ))}
        </div>

        <div className="flex items-center gap-3 overflow-x-auto pb-2">
          <Filter className="w-5 h-5 text-muted-foreground" />
          {filters.map((filter) => (
            <button
              key={filter}
              onClick={() => setActiveFilter(filter)}
              className={`px-4 py-2 rounded-full whitespace-nowrap transition-colors ${
                activeFilter === filter
                  ? 'bg-primary text-primary-foreground'
                  : 'bg-muted text-foreground hover:bg-muted/80'
              }`}
            >
              {filter === 'all' ? 'Tous' : filter}
            </button>
          ))}
        </div>

        <div className="space-y-4">
          {feedbacks.map((feedback) => {
            const Icon = feedback.icon;
            return (
              <Card key={feedback.id}>
                <div className="space-y-4">
                  <div className="flex items-start justify-between gap-4">
                    <div className="flex items-start gap-3 flex-1">
                      <div className="w-10 h-10 rounded-xl bg-muted flex items-center justify-center shrink-0">
                        <Icon className={`w-5 h-5 ${feedback.color}`} />
                      </div>
                      <div className="flex-1">
                        <div className="flex items-center gap-2 mb-2">
                          <Badge variant="beta">{feedback.chapter}</Badge>
                          <Badge
                            variant={
                              feedback.priority === 'high'
                                ? 'rejected'
                                : feedback.priority === 'medium'
                                ? 'correcting'
                                : 'draft'
                            }
                          >
                            {feedback.type}
                          </Badge>
                        </div>
                        <p className="font-medium mb-1">{feedback.text}</p>
                        <p className="text-sm text-muted-foreground italic mb-2">
                          "{feedback.excerpt}"
                        </p>
                        <p className="text-sm text-muted-foreground">
                          Par {feedback.beta}
                        </p>
                      </div>
                    </div>
                  </div>

                  <div className="flex gap-2">
                    <Button variant="outline" size="sm" onClick={() => onNavigate('editor')}>
                      <ExternalLink className="w-4 h-4" />
                      Ouvrir dans l'éditeur
                    </Button>
                    <Button variant="ghost" size="sm">
                      <CheckCircle className="w-4 h-4" />
                      Marquer comme traité
                    </Button>
                  </div>
                </div>
              </Card>
            );
          })}
        </div>
      </div>
    </div>
  );
}
