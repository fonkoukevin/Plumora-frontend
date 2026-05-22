import { useState } from 'react';
import { Card } from '../components/Card';
import { Button } from '../components/Button';
import { Star, Share2, ThumbsUp, Heart } from 'lucide-react';

interface BookReviewPageProps {
  onNavigate: (page: string) => void;
}

export function BookReviewPage({ onNavigate }: BookReviewPageProps) {
  const [rating, setRating] = useState(0);
  const [hoverRating, setHoverRating] = useState(0);
  const [review, setReview] = useState('');

  const handleSubmit = () => {
    onNavigate('discover');
  };

  return (
    <div className="min-h-screen bg-background flex items-center justify-center p-4">
      <Card className="max-w-2xl w-full">
        <div className="text-center space-y-6">
          <div className="space-y-4">
            <div className="text-6xl">🎉</div>
            <h1 className="text-3xl font-bold">Tu as terminé La Nuit Rouge</h1>
            <p className="text-muted-foreground">
              Partage ton avis pour aider d'autres lecteurs à découvrir ce livre
            </p>
          </div>

          <div className="space-y-4">
            <div className="space-y-2">
              <p className="font-medium">Note ce livre</p>
              <div className="flex justify-center gap-2">
                {[1, 2, 3, 4, 5].map((star) => (
                  <button
                    key={star}
                    onMouseEnter={() => setHoverRating(star)}
                    onMouseLeave={() => setHoverRating(0)}
                    onClick={() => setRating(star)}
                    className="transition-transform hover:scale-110"
                  >
                    <Star
                      className={`w-10 h-10 ${
                        star <= (hoverRating || rating)
                          ? 'fill-yellow-400 text-yellow-400'
                          : 'text-gray-300'
                      }`}
                    />
                  </button>
                ))}
              </div>
              {rating > 0 && (
                <p className="text-sm text-muted-foreground">
                  {rating === 1 && 'Décevant'}
                  {rating === 2 && 'Moyen'}
                  {rating === 3 && 'Bien'}
                  {rating === 4 && 'Très bien'}
                  {rating === 5 && 'Excellent'}
                </p>
              )}
            </div>

            <div className="space-y-2">
              <label className="font-medium text-left block">
                Laisse ton avis (optionnel)
              </label>
              <textarea
                value={review}
                onChange={(e) => setReview(e.target.value)}
                placeholder="Qu'as-tu pensé de ce livre ? Partage ton ressenti..."
                className="w-full px-4 py-3 rounded-xl bg-input-background border border-border focus:outline-none focus:ring-2 focus:ring-ring transition-all min-h-32 resize-y"
              />
            </div>
          </div>

          <div className="space-y-3">
            <Button
              className="w-full"
              size="lg"
              onClick={handleSubmit}
              disabled={rating === 0}
            >
              <ThumbsUp className="w-5 h-5" />
              Publier mon avis
            </Button>

            <div className="flex gap-3">
              <Button variant="outline" className="flex-1" onClick={handleSubmit}>
                <Share2 className="w-4 h-4" />
                Partager le livre
              </Button>
              <Button variant="outline" className="flex-1" onClick={() => onNavigate('discover')}>
                <Heart className="w-4 h-4" />
                Ajouter aux favoris
              </Button>
            </div>
          </div>

          <button
            onClick={() => onNavigate('discover')}
            className="text-sm text-muted-foreground hover:text-foreground transition-colors"
          >
            Passer cette étape
          </button>
        </div>
      </Card>
    </div>
  );
}
