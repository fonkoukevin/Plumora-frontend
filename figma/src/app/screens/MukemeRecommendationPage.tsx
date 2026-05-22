import { useState } from 'react';
import { Card } from '../components/Card';
import { Button } from '../components/Button';
import { ArrowLeft, Sparkles, Send } from 'lucide-react';

interface MukemeRecommendationPageProps {
  onNavigate: (page: string) => void;
}

export function MukemeRecommendationPage({ onNavigate }: MukemeRecommendationPageProps) {
  const [query, setQuery] = useState('');
  const [selectedMood, setSelectedMood] = useState<string[]>([]);
  const [selectedDuration, setSelectedDuration] = useState('');
  const [selectedGenres, setSelectedGenres] = useState<string[]>([]);

  const moods = [
    { id: 'calm', label: 'Calme', emoji: '🌙' },
    { id: 'romance', label: 'Romance', emoji: '💕' },
    { id: 'suspense', label: 'Suspense', emoji: '😱' },
    { id: 'motivation', label: 'Motivation', emoji: '💪' },
    { id: 'evasion', label: 'Évasion', emoji: '✈️' },
  ];

  const durations = [
    { id: 'short', label: 'Court', time: '< 2h' },
    { id: 'medium', label: 'Moyen', time: '2-5h' },
    { id: 'long', label: 'Long', time: '> 5h' },
  ];

  const genres = [
    { id: 'thriller', label: 'Thriller' },
    { id: 'romance', label: 'Romance' },
    { id: 'fantasy', label: 'Fantasy' },
    { id: 'scifi', label: 'Science-Fiction' },
    { id: 'personal', label: 'Développement personnel' },
    { id: 'mystery', label: 'Mystère' },
  ];

  const toggleMood = (id: string) => {
    setSelectedMood((prev) =>
      prev.includes(id) ? prev.filter((m) => m !== id) : [...prev, id]
    );
  };

  const toggleGenre = (id: string) => {
    setSelectedGenres((prev) =>
      prev.includes(id) ? prev.filter((g) => g !== id) : [...prev, id]
    );
  };

  const handleRecommend = () => {
    onNavigate('mukeme-results');
  };

  return (
    <div className="min-h-screen bg-background pb-8">
      <div className="max-w-4xl mx-auto px-4 py-8 space-y-8">
        <button
          onClick={() => onNavigate('discover')}
          className="flex items-center gap-2 text-muted-foreground hover:text-foreground transition-colors"
        >
          <ArrowLeft className="w-5 h-5" />
          Retour
        </button>

        <div className="text-center space-y-4">
          <div className="w-20 h-20 mx-auto rounded-full bg-gradient-to-br from-primary to-purple-600 flex items-center justify-center">
            <Sparkles className="w-10 h-10 text-white" />
          </div>
          <h1 className="text-4xl font-bold text-foreground">Mukeme</h1>
          <p className="text-xl text-muted-foreground">Assistant de lecture</p>
        </div>

        <Card>
          <div className="space-y-4">
            <h2 className="text-xl font-semibold">
              Quel type de livre veux-tu lire aujourd'hui ?
            </h2>
            <textarea
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Je veux une histoire courte, sombre, avec du suspense et une fin surprenante."
              className="w-full px-4 py-3 rounded-xl bg-input-background border border-border focus:outline-none focus:ring-2 focus:ring-ring transition-all min-h-32 resize-y"
            />
          </div>
        </Card>

        <Card>
          <div className="space-y-4">
            <h3 className="font-semibold">Humeur du moment</h3>
            <div className="grid grid-cols-2 md:grid-cols-5 gap-3">
              {moods.map((mood) => (
                <button
                  key={mood.id}
                  onClick={() => toggleMood(mood.id)}
                  className={`flex flex-col items-center gap-2 p-4 rounded-xl border-2 transition-all ${
                    selectedMood.includes(mood.id)
                      ? 'border-primary bg-purple-50'
                      : 'border-border hover:border-primary/50'
                  }`}
                >
                  <span className="text-3xl">{mood.emoji}</span>
                  <span className="text-sm font-medium">{mood.label}</span>
                </button>
              ))}
            </div>
          </div>
        </Card>

        <Card>
          <div className="space-y-4">
            <h3 className="font-semibold">Durée de lecture</h3>
            <div className="grid grid-cols-3 gap-3">
              {durations.map((duration) => (
                <button
                  key={duration.id}
                  onClick={() => setSelectedDuration(duration.id)}
                  className={`flex flex-col items-center gap-2 p-4 rounded-xl border-2 transition-all ${
                    selectedDuration === duration.id
                      ? 'border-primary bg-purple-50'
                      : 'border-border hover:border-primary/50'
                  }`}
                >
                  <span className="font-semibold">{duration.label}</span>
                  <span className="text-sm text-muted-foreground">{duration.time}</span>
                </button>
              ))}
            </div>
          </div>
        </Card>

        <Card>
          <div className="space-y-4">
            <h3 className="font-semibold">Genres préférés</h3>
            <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
              {genres.map((genre) => (
                <button
                  key={genre.id}
                  onClick={() => toggleGenre(genre.id)}
                  className={`p-3 rounded-xl border-2 transition-all ${
                    selectedGenres.includes(genre.id)
                      ? 'border-primary bg-purple-50'
                      : 'border-border hover:border-primary/50'
                  }`}
                >
                  <span className="font-medium">{genre.label}</span>
                </button>
              ))}
            </div>
          </div>
        </Card>

        <Button
          className="w-full"
          size="lg"
          onClick={handleRecommend}
          disabled={!query.trim() && selectedMood.length === 0}
        >
          <Sparkles className="w-5 h-5" />
          Me recommander
        </Button>
      </div>
    </div>
  );
}
