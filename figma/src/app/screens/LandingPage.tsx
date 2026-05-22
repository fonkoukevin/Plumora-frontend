import { Button } from '../components/Button';
import { BookOpen, Feather, Monitor, Library, Quote } from 'lucide-react';

interface LandingPageProps {
  onNavigate: (page: string) => void;
}

export function LandingPage({ onNavigate }: LandingPageProps) {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-background px-4">
      <div className="max-w-4xl w-full text-center space-y-12">
        <div className="space-y-6">
          <div className="flex items-center justify-center gap-3">
            <Feather className="w-12 h-12 text-primary" strokeWidth={1.5} />
            <h1 className="text-6xl font-bold text-primary">Plumora</h1>
          </div>

          <p className="text-2xl text-foreground font-medium">
            Écris. Publie. Lis. Partage.
          </p>

          <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
            La plateforme qui accompagne les auteurs de l'écriture à la publication,
            et aide les lecteurs à découvrir leur prochain livre.
          </p>
        </div>

        <div className="bg-gradient-to-r from-amber-50 to-orange-50 border border-primary/20 rounded-2xl p-6 max-w-2xl mx-auto">
          <div className="flex items-start gap-4">
            <div className="w-12 h-12 rounded-xl bg-white/80 flex items-center justify-center shrink-0">
              <Quote className="w-6 h-6 text-primary" />
            </div>
            <div className="flex-1 pt-1">
              <p className="text-foreground italic mb-2">
                "N'attendez pas l'inspiration. Elle vient en écrivant."
              </p>
              <p className="text-sm text-muted-foreground font-medium">— Victor Hugo</p>
            </div>
          </div>
        </div>

        <div className="flex gap-4 justify-center">
          <Button size="lg" onClick={() => onNavigate('login')}>
            Se connecter
          </Button>
          <Button size="lg" variant="outline" onClick={() => onNavigate('signup')}>
            Créer un compte
          </Button>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mt-16">
          <div className="flex flex-col items-center gap-4 p-6">
            <div className="w-16 h-16 rounded-2xl bg-secondary flex items-center justify-center shadow-sm">
              <Monitor className="w-8 h-8 text-primary" />
            </div>
            <h3 className="font-semibold">Écrire</h3>
            <p className="text-sm text-muted-foreground text-center">
              Un éditeur puissant pour donner vie à vos histoires
            </p>
          </div>

          <div className="flex flex-col items-center gap-4 p-6">
            <div className="w-16 h-16 rounded-2xl bg-secondary flex items-center justify-center shadow-sm">
              <BookOpen className="w-8 h-8 text-primary" />
            </div>
            <h3 className="font-semibold">Publier</h3>
            <p className="text-sm text-muted-foreground text-center">
              Partagez vos œuvres avec une communauté passionnée
            </p>
          </div>

          <div className="flex flex-col items-center gap-4 p-6">
            <div className="w-16 h-16 rounded-2xl bg-[#E6EFE4] flex items-center justify-center shadow-sm">
              <Library className="w-8 h-8 text-accent" />
            </div>
            <h3 className="font-semibold">Découvrir</h3>
            <p className="text-sm text-muted-foreground text-center">
              Des milliers de livres à explorer et à aimer
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
