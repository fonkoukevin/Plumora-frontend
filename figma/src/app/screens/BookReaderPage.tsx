import { useState } from 'react';
import { Button } from '../components/Button';
import {
  ArrowLeft,
  ChevronLeft,
  ChevronRight,
  Bookmark,
  Settings,
  MessageSquare,
  Star,
} from 'lucide-react';

interface BookReaderPageProps {
  onNavigate: (page: string) => void;
}

export function BookReaderPage({ onNavigate }: BookReaderPageProps) {
  const [currentPage, setCurrentPage] = useState(1);
  const totalPages = 234;

  const handleNextPage = () => {
    if (currentPage === totalPages) {
      onNavigate('book-review');
    } else {
      setCurrentPage(currentPage + 1);
    }
  };

  return (
    <div className="min-h-screen bg-background flex flex-col">
      <header className="bg-card border-b border-border px-4 py-3 flex items-center justify-between sticky top-0 z-10">
        <button
          onClick={() => onNavigate('library')}
          className="flex items-center gap-2 text-muted-foreground hover:text-foreground transition-colors"
        >
          <ArrowLeft className="w-5 h-5" />
          <span className="hidden md:inline">Retour</span>
        </button>

        <div className="flex-1 text-center">
          <h2 className="font-semibold truncate">Les Chroniques d'Eldoria</h2>
          <p className="text-sm text-muted-foreground">
            Chapitre 5 - La Forêt Enchantée
          </p>
        </div>

        <div className="flex items-center gap-2">
          <button className="p-2 hover:bg-muted rounded-lg transition-colors">
            <Bookmark className="w-5 h-5" />
          </button>
          <button className="p-2 hover:bg-muted rounded-lg transition-colors">
            <Settings className="w-5 h-5" />
          </button>
        </div>
      </header>

      <div className="flex-1 overflow-y-auto">
        <div className="max-w-3xl mx-auto px-6 py-8">
          <div className="prose prose-lg max-w-none">
            <p className="text-foreground leading-relaxed mb-6">
              La forêt d'Eldoria s'étendait devant Clara comme un océan de verdure et de
              mystères. Les arbres centenaires, dont les troncs massifs auraient pu
              contenir des maisons entières, formaient une cathédrale naturelle où la
              lumière du soleil peinait à percer.
            </p>

            <p className="text-foreground leading-relaxed mb-6">
              "Nous devons être prudents," murmura Elias en scrutant les ombres entre les
              arbres. "La forêt n'a pas toujours été bienveillante avec les étrangers."
            </p>

            <p className="text-foreground leading-relaxed mb-6">
              Clara hocha la tête, sentant une étrange énergie pulser autour d'elle. C'était
              comme si la forêt elle-même était vivante, consciente de leur présence. Les
              feuilles bruissaient doucement, portées par un vent qui ne venait d'aucune
              direction particulière.
            </p>

            <p className="text-foreground leading-relaxed mb-6">
              Au loin, un chant mélodieux s'éleva, si beau qu'il en était presque douloureux.
              Clara sentit ses jambes se mettre en mouvement malgré elle, attirée par cette
              voix enchanteresse qui promettait repos et réconfort.
            </p>

            <p className="text-foreground leading-relaxed mb-6">
              "Non !" cria Elias en l'attrapant par le bras. "C'est un piège ! Les sirènes
              de la forêt attirent les voyageurs pour les perdre à jamais dans les
              méandres des bois."
            </p>

            <p className="text-foreground leading-relaxed mb-6">
              Clara secoua la tête, tentant de chasser l'emprise du chant. Peu à peu, la
              mélodie s'estompa, remplacée par le bruissement normal de la forêt. Elle
              réalisa à quel point elle était passée près du danger.
            </p>

            <p className="text-foreground leading-relaxed mb-6">
              "Merci," souffla-t-elle, encore tremblante. "Je ne sais pas ce qui m'a pris."
            </p>

            <p className="text-foreground leading-relaxed mb-6">
              Elias esquissa un sourire rassurant. "La magie d'Eldoria est puissante.
              Même les plus forts peuvent succomber à ses charmes. C'est pour cela que
              nous devons rester vigilants."
            </p>

            <p className="text-foreground leading-relaxed mb-6">
              Ils reprirent leur chemin, avançant prudemment entre les arbres gigantesques.
              Chaque pas les menait plus profondément dans le cœur de la forêt, là où
              personne n'osait s'aventurer depuis des générations.
            </p>
          </div>
        </div>
      </div>

      <footer className="bg-card border-t border-border px-4 py-4">
        <div className="max-w-3xl mx-auto space-y-4">
          <div className="flex items-center justify-between text-sm text-muted-foreground">
            <span>
              Page {currentPage} sur {totalPages}
            </span>
            <span>{Math.round((currentPage / totalPages) * 100)}% lu</span>
          </div>

          <div className="h-1 bg-muted rounded-full overflow-hidden">
            <div
              className="h-full bg-primary transition-all"
              style={{ width: `${(currentPage / totalPages) * 100}%` }}
            />
          </div>

          <div className="flex items-center justify-between gap-4">
            <Button
              variant="outline"
              size="sm"
              onClick={() => setCurrentPage(Math.max(1, currentPage - 1))}
              disabled={currentPage === 1}
            >
              <ChevronLeft className="w-4 h-4" />
              Précédent
            </Button>

            <div className="flex gap-2">
              <button className="p-2 hover:bg-muted rounded-lg transition-colors">
                <MessageSquare className="w-5 h-5 text-muted-foreground" />
              </button>
              <button className="p-2 hover:bg-muted rounded-lg transition-colors">
                <Star className="w-5 h-5 text-muted-foreground" />
              </button>
            </div>

            <Button
              size="sm"
              onClick={handleNextPage}
            >
              {currentPage === totalPages ? 'Terminer' : 'Suivant'}
              <ChevronRight className="w-4 h-4" />
            </Button>
          </div>
        </div>
      </footer>
    </div>
  );
}
