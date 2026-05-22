import { Card } from '../components/Card';
import { Button } from '../components/Button';
import { Badge } from '../components/Badge';
import { MobileNav } from '../components/MobileNav';
import {
  User,
  Mail,
  Calendar,
  BookOpen,
  Feather,
  TestTube,
  Settings,
  LogOut,
  Shield,
  Bell,
  Sparkles,
  Clock,
  CreditCard,
  Edit3,
  Award,
} from 'lucide-react';

interface ProfilePageProps {
  onNavigate: (page: string) => void;
}

export function ProfilePage({ onNavigate }: ProfilePageProps) {
  return (
    <div className="min-h-screen bg-background pb-20 md:pb-8">
      <div className="max-w-4xl mx-auto px-4 py-8 space-y-6">
        <div className="bg-primary rounded-3xl p-8 text-white relative overflow-hidden shadow-md">
          <div className="absolute top-4 right-4">
            <button className="w-10 h-10 rounded-xl bg-white/20 backdrop-blur-sm flex items-center justify-center hover:bg-white/30 transition-colors">
              <CreditCard className="w-5 h-5" />
            </button>
          </div>

          <div className="flex flex-col items-center text-center space-y-4">
            <div className="w-20 h-20 rounded-full bg-white/20 backdrop-blur-sm flex items-center justify-center text-2xl font-bold border-2 border-white/30">
              KM
            </div>
            <div>
              <h1 className="text-3xl font-bold">Kevin Martin</h1>
              <p className="text-white/90 mt-1">Auteur passionné</p>
            </div>
          </div>

          <div className="mt-6">
            <Button
              variant="outline"
              className="w-full bg-white/10 backdrop-blur-sm border-white/30 text-white hover:bg-white/20"
            >
              <Edit3 className="w-4 h-4" />
              Modifier le profil
            </Button>
          </div>
        </div>

        <Card>
          <div className="flex items-center justify-around">
            <div className="text-center">
              <BookOpen className="w-5 h-5 text-muted-foreground mx-auto mb-2" />
              <p className="text-2xl font-bold text-foreground">12</p>
              <p className="text-xs text-muted-foreground mt-1">Manuscrits</p>
            </div>

            <div className="text-center">
              <Feather className="w-5 h-5 text-muted-foreground mx-auto mb-2" />
              <p className="text-2xl font-bold text-foreground">248K</p>
              <p className="text-xs text-muted-foreground mt-1">Mots</p>
            </div>

            <div className="text-center">
              <Clock className="w-5 h-5 text-muted-foreground mx-auto mb-2" />
              <p className="text-2xl font-bold text-foreground">456</p>
              <p className="text-xs text-muted-foreground mt-1">Heures</p>
            </div>

            <div className="text-center">
              <Award className="w-5 h-5 text-muted-foreground mx-auto mb-2" />
              <p className="text-2xl font-bold text-foreground">8</p>
              <p className="text-xs text-muted-foreground mt-1">Prix</p>
            </div>
          </div>
        </Card>

        <div>
          <h2 className="text-lg font-bold text-foreground mb-3">À propos</h2>
          <Card>
            <p className="text-sm text-muted-foreground leading-relaxed">
              Passionnée d'écriture depuis mon plus jeune âge, je crée des mondes où la magie rencontre l'émotion.
            </p>
          </Card>
        </div>

        <div className="space-y-4">
          <h2 className="text-2xl font-semibold">Activité</h2>

          <Card hover className="cursor-pointer">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 rounded-xl bg-blue-100 flex items-center justify-center">
                <Clock className="w-6 h-6 text-blue-600" />
              </div>
              <div className="flex-1">
                <h3 className="font-semibold">Historique de lecture</h3>
                <p className="text-sm text-muted-foreground">
                  Tous les livres que vous avez lus
                </p>
              </div>
            </div>
          </Card>
        </div>

        <div className="space-y-4">
          <h2 className="text-2xl font-semibold">Paramètres</h2>

          <Card hover className="cursor-pointer">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 rounded-xl bg-secondary flex items-center justify-center">
                <User className="w-6 h-6 text-primary" />
              </div>
              <div className="flex-1">
                <h3 className="font-semibold">Informations personnelles</h3>
                <p className="text-sm text-muted-foreground">
                  Modifier votre nom, email et photo de profil
                </p>
              </div>
            </div>
          </Card>

          <Card hover className="cursor-pointer">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 rounded-xl bg-[#E8F0F5] flex items-center justify-center">
                <Bell className="w-6 h-6" style={{ color: '#7E93A8' }} />
              </div>
              <div className="flex-1">
                <h3 className="font-semibold">Notifications</h3>
                <p className="text-sm text-muted-foreground">
                  Gérer vos préférences de notification
                </p>
              </div>
            </div>
          </Card>

          <Card hover className="cursor-pointer">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 rounded-xl bg-[#E6EFE4] flex items-center justify-center">
                <Sparkles className="w-6 h-6 text-accent" />
              </div>
              <div className="flex-1">
                <h3 className="font-semibold">Assistant Mukeme</h3>
                <p className="text-sm text-muted-foreground">
                  Configurer votre assistant IA d'écriture
                </p>
              </div>
            </div>
          </Card>

          <Card hover className="cursor-pointer">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 rounded-xl bg-[#E6F0E7] flex items-center justify-center">
                <Shield className="w-6 h-6" style={{ color: '#6E9B74' }} />
              </div>
              <div className="flex-1">
                <h3 className="font-semibold">Confidentialité & Sécurité</h3>
                <p className="text-sm text-muted-foreground">
                  Mot de passe, authentification et visibilité
                </p>
              </div>
            </div>
          </Card>

          <Card hover className="cursor-pointer">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 rounded-xl bg-muted flex items-center justify-center">
                <Settings className="w-6 h-6 text-muted-foreground" />
              </div>
              <div className="flex-1">
                <h3 className="font-semibold">Préférences</h3>
                <p className="text-sm text-muted-foreground">
                  Langue, thème et autres paramètres
                </p>
              </div>
            </div>
          </Card>
        </div>

        <div className="pt-4">
          <Button
            variant="outline"
            className="w-full text-destructive border-destructive hover:bg-destructive hover:text-destructive-foreground"
            onClick={() => onNavigate('landing')}
          >
            <LogOut className="w-4 h-4" />
            Se déconnecter
          </Button>
        </div>
      </div>

      <MobileNav currentPage="profile" onNavigate={onNavigate} />
    </div>
  );
}
