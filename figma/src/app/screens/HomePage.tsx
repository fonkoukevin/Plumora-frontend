import { Card } from '../components/Card';
import { Button } from '../components/Button';
import { MobileNav } from '../components/MobileNav';
import { Logo } from '../components/Logo';
import { BookOpen, TestTube, TrendingUp, PenTool, MessageSquare, CheckCircle, Quote, Bell, User } from 'lucide-react';

interface HomePageProps {
  onNavigate: (page: string) => void;
}

export function HomePage({ onNavigate }: HomePageProps) {
  return (
    <div className="min-h-screen bg-background pb-20 md:pb-8">
      <div className="max-w-7xl mx-auto px-4 py-6 space-y-8">
        <header className="flex items-center justify-between">
          <div>
            <Logo size="lg" />
            <p className="text-xl font-medium text-foreground mt-2">Bonjour, Kevin 👋</p>
          </div>
          <div className="flex items-center gap-3">
            <button className="w-10 h-10 rounded-xl hover:bg-muted flex items-center justify-center transition-colors">
              <Bell className="w-5 h-5 text-muted-foreground" />
            </button>
            <button
              onClick={() => onNavigate('profile')}
              className="w-10 h-10 rounded-xl bg-gradient-to-br from-primary to-purple-700 flex items-center justify-center shadow-lg shadow-primary/30 hover:scale-105 transition-transform"
            >
              <User className="w-5 h-5 text-white" />
            </button>
          </div>
        </header>

        <div className="bg-secondary rounded-2xl p-5 border border-border">
          <div className="flex items-start gap-4">
            <Quote className="w-7 h-7 text-primary shrink-0 mt-0.5" />
            <div className="flex-1 text-center">
              <p className="text-foreground italic text-sm leading-relaxed">
                "N'attendez pas l'inspiration. Elle vient en écrivant."
              </p>
              <p className="text-xs text-muted-foreground mt-2">— Victor Hugo</p>
            </div>
          </div>
        </div>

        <div>
          <h2 className="text-xl font-bold text-foreground mb-4">Vos manuscrits</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <Card hover onClick={() => onNavigate('write')} className="group relative overflow-hidden border border-border hover:border-primary hover:shadow-md transition-all">
            <div className="absolute top-0 right-0 w-32 h-32 bg-secondary rounded-bl-full -mr-16 -mt-16" />
            <div className="relative flex items-start gap-5">
              <div className="w-14 h-14 rounded-xl bg-primary flex items-center justify-center shrink-0 shadow-sm">
                <PenTool className="w-7 h-7 text-white" />
              </div>
              <div className="flex-1">
                <h3 className="text-lg font-bold mb-1.5 group-hover:text-primary transition-colors">
                  Continuer à écrire
                </h3>
                <p className="text-sm text-muted-foreground mb-2">
                  La Nuit Rouge - Chapitre 3
                </p>
                <div className="flex items-center gap-2">
                  <div className="h-1.5 bg-muted rounded-full flex-1 overflow-hidden">
                    <div className="h-full bg-primary w-[35%]" />
                  </div>
                  <span className="text-xs font-semibold text-primary">35%</span>
                </div>
              </div>
            </div>
          </Card>

          <Card hover onClick={() => onNavigate('discover')} className="group relative overflow-hidden border border-border hover:border-primary hover:shadow-md transition-all">
            <div className="absolute top-0 right-0 w-32 h-32 bg-secondary rounded-bl-full -mr-16 -mt-16" />
            <div className="relative flex items-start gap-5">
              <div className="w-14 h-14 rounded-xl bg-primary flex items-center justify-center shrink-0 shadow-sm">
                <BookOpen className="w-7 h-7 text-white" />
              </div>
              <div className="flex-1">
                <h3 className="text-lg font-bold mb-1.5 group-hover:text-primary transition-colors">
                  Découvrir un livre
                </h3>
                <p className="text-sm text-muted-foreground">
                  Explorez des milliers de livres
                </p>
                <p className="text-xs text-accent font-medium mt-2">
                  ✨ Recommandé par Mukeme
                </p>
              </div>
            </div>
          </Card>

          <Card hover onClick={() => onNavigate('library')} className="group relative overflow-hidden border border-border hover:border-primary hover:shadow-md transition-all">
            <div className="absolute top-0 right-0 w-32 h-32 bg-secondary rounded-bl-full -mr-16 -mt-16" />
            <div className="relative flex items-start gap-5">
              <div className="w-14 h-14 rounded-xl bg-accent flex items-center justify-center shrink-0 shadow-sm">
                <TestTube className="w-7 h-7 text-white" />
              </div>
              <div className="flex-1">
                <h3 className="text-lg font-bold mb-1.5 group-hover:text-primary transition-colors">
                  Mes bêta-lectures
                </h3>
                <p className="text-sm text-muted-foreground">
                  2 manuscrits en attente
                </p>
                <p className="text-xs font-medium mt-2" style={{ color: '#D9A441' }}>
                  ⏰ Deadline : 12 juin
                </p>
              </div>
            </div>
          </Card>
          </div>
        </div>

        <div className="space-y-6">
          <div className="flex items-center justify-between">
            <h2 className="text-xl font-bold text-foreground">Activité récente</h2>
            <button className="text-primary hover:underline text-sm font-medium">
              Tout voir
            </button>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <Card className="border-l-4 border-l-primary hover:shadow-md transition-shadow">
              <div className="flex items-start gap-4">
                <div className="w-12 h-12 rounded-xl bg-secondary flex items-center justify-center shrink-0">
                  <PenTool className="w-6 h-6 text-primary" />
                </div>
                <div className="flex-1">
                  <p className="font-semibold mb-1">Chapitre 3 modifié</p>
                  <p className="text-sm text-muted-foreground">La Nuit Rouge</p>
                  <p className="text-xs text-primary font-medium mt-2">Il y a 2h</p>
                </div>
              </div>
            </Card>

            <Card className="border-l-4 border-l-accent hover:shadow-md transition-shadow">
              <div className="flex items-start gap-4">
                <div className="w-12 h-12 rounded-xl bg-[#E6EFE4] flex items-center justify-center shrink-0">
                  <MessageSquare className="w-6 h-6 text-accent" />
                </div>
                <div className="flex-1">
                  <p className="font-semibold mb-1">4 nouveaux retours bêta</p>
                  <p className="text-sm text-muted-foreground">Les Ombres de Minuit</p>
                  <p className="text-xs text-accent font-medium mt-2">Hier</p>
                </div>
              </div>
            </Card>

            <Card className="border-l-4 border-l-primary hover:shadow-md transition-shadow">
              <div className="flex items-start gap-4">
                <div className="w-12 h-12 rounded-xl bg-secondary flex items-center justify-center shrink-0">
                  <CheckCircle className="w-6 h-6 text-[#6E9B74]" />
                </div>
                <div className="flex-1">
                  <p className="font-semibold mb-1">Livre publié 🎉</p>
                  <p className="text-sm text-muted-foreground">Sang d'Encre</p>
                  <p className="text-xs text-primary font-medium mt-2">Il y a 3 jours</p>
                </div>
              </div>
            </Card>
          </div>
        </div>
      </div>

      <MobileNav currentPage="home" onNavigate={onNavigate} />
    </div>
  );
}
