import { useState } from 'react';
import { Card } from '../components/Card';
import { Button } from '../components/Button';
import { MobileNav } from '../components/MobileNav';
import {
  User, Mail, Calendar, BookOpen, Feather, Settings, LogOut,
  Shield, Bell, Sparkles, Clock, CreditCard, Edit3, Award,
  ChevronLeft, ChevronRight, Camera, Phone, MapPin, Check,
} from 'lucide-react';

interface ProfilePageProps {
  onNavigate: (page: string) => void;
}

const INITIAL_USER = {
  firstName: 'Kevin',
  lastName: 'Martin',
  email: 'kevin.martin@email.com',
  phone: '+33 6 12 34 56 78',
  location: 'Paris, France',
  birthdate: '1995-04-12',
  bio: "Passionné d'écriture depuis mon plus jeune âge, je crée des mondes où la magie rencontre l'émotion.",
  role: 'Auteur passionné',
};

function PersonalInfoPage({ onBack }: { onBack: () => void }) {
  const [user, setUser] = useState(INITIAL_USER);
  const [editing, setEditing] = useState(false);
  const [draft, setDraft] = useState(INITIAL_USER);
  const [saved, setSaved] = useState(false);

  const handleSave = () => {
    setUser(draft);
    setEditing(false);
    setSaved(true);
    setTimeout(() => setSaved(false), 2000);
  };

  const handleCancel = () => {
    setDraft(user);
    setEditing(false);
  };

  const fields = [
    { key: 'firstName', label: 'Prénom', icon: User, type: 'text' },
    { key: 'lastName', label: 'Nom', icon: User, type: 'text' },
    { key: 'email', label: 'Email', icon: Mail, type: 'email' },
    { key: 'phone', label: 'Téléphone', icon: Phone, type: 'tel' },
    { key: 'location', label: 'Localisation', icon: MapPin, type: 'text' },
    { key: 'birthdate', label: 'Date de naissance', icon: Calendar, type: 'date' },
    { key: 'role', label: 'Titre / Rôle', icon: Feather, type: 'text' },
  ] as const;

  return (
    <div className="min-h-screen bg-background pb-24 md:pb-8">
      {/* Header */}
      <div className="sticky top-0 z-30 bg-background/95 border-b border-border px-4 pt-5 pb-3" style={{ backdropFilter: 'blur(12px)' }}>
        <div className="max-w-lg mx-auto flex items-center justify-between">
          <button
            onClick={onBack}
            className="flex items-center gap-1.5 text-sm font-semibold text-primary hover:text-primary/80 transition-colors"
          >
            <ChevronLeft className="w-4 h-4" />
            Profil
          </button>
          <h1 className="text-base font-bold text-foreground">Informations personnelles</h1>
          <button
            onClick={() => editing ? handleSave() : setEditing(true)}
            className="text-sm font-bold transition-colors"
            style={{ color: editing ? '#8B5E3C' : '#6D3A5D' }}
          >
            {editing ? 'Enregistrer' : 'Modifier'}
          </button>
        </div>
      </div>

      <div className="max-w-lg mx-auto px-4 pt-5 space-y-5">

        {/* Feedback succès */}
        {saved && (
          <div className="flex items-center gap-2 px-4 py-3 rounded-2xl bg-green-50 border border-green-200 text-green-700 text-sm font-semibold">
            <Check className="w-4 h-4" />
            Modifications enregistrées
          </div>
        )}

        {/* Avatar */}
        <div className="flex flex-col items-center gap-3 py-4">
          <div className="relative">
            <div
              className="w-24 h-24 rounded-full flex items-center justify-center text-2xl font-bold text-white shadow-lg"
              style={{ background: 'linear-gradient(135deg, #8B5E3C, #6D3A5D)' }}
            >
              {user.firstName[0]}{user.lastName[0]}
            </div>
            {editing && (
              <button
                className="absolute bottom-0 right-0 w-8 h-8 rounded-full bg-primary flex items-center justify-center shadow-md border-2 border-background"
              >
                <Camera className="w-4 h-4 text-white" />
              </button>
            )}
          </div>
          {!editing && (
            <div className="text-center">
              <p className="font-bold text-lg text-foreground">{user.firstName} {user.lastName}</p>
              <p className="text-sm text-muted-foreground">{user.role}</p>
            </div>
          )}
        </div>

        {/* Champs */}
        <div className="space-y-3">
          {fields.map(({ key, label, icon: Icon, type }) => (
            <div key={key} className="bg-card border border-border rounded-2xl px-4 py-3">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-lg flex items-center justify-center shrink-0" style={{ backgroundColor: 'rgba(139,94,60,0.1)' }}>
                  <Icon className="w-4 h-4 text-primary" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-xs text-muted-foreground font-medium mb-0.5">{label}</p>
                  {editing ? (
                    <input
                      type={type}
                      value={draft[key]}
                      onChange={(e) => setDraft({ ...draft, [key]: e.target.value })}
                      className="w-full text-sm font-semibold text-foreground bg-transparent border-b border-primary/40 focus:outline-none focus:border-primary pb-0.5"
                    />
                  ) : (
                    <p className="text-sm font-semibold text-foreground truncate">
                      {key === 'birthdate'
                        ? new Date(user[key]).toLocaleDateString('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' })
                        : user[key]}
                    </p>
                  )}
                </div>
              </div>
            </div>
          ))}

          {/* Bio */}
          <div className="bg-card border border-border rounded-2xl px-4 py-3">
            <div className="flex items-start gap-3">
              <div className="w-8 h-8 rounded-lg flex items-center justify-center shrink-0 mt-0.5" style={{ backgroundColor: 'rgba(109,58,93,0.1)' }}>
                <Edit3 className="w-4 h-4 text-secondary" />
              </div>
              <div className="flex-1">
                <p className="text-xs text-muted-foreground font-medium mb-0.5">Biographie</p>
                {editing ? (
                  <textarea
                    value={draft.bio}
                    onChange={(e) => setDraft({ ...draft, bio: e.target.value })}
                    rows={3}
                    className="w-full text-sm font-medium text-foreground bg-transparent border border-primary/30 rounded-lg p-2 focus:outline-none focus:border-primary resize-none mt-1"
                  />
                ) : (
                  <p className="text-sm text-foreground leading-relaxed">{user.bio}</p>
                )}
              </div>
            </div>
          </div>
        </div>

        {/* Boutons annuler/enregistrer en mode édition */}
        {editing && (
          <div className="flex gap-3 pt-2">
            <button
              onClick={handleCancel}
              className="flex-1 py-3 rounded-2xl border border-border text-sm font-bold text-muted-foreground hover:bg-muted transition-colors"
            >
              Annuler
            </button>
            <button
              onClick={handleSave}
              className="flex-1 py-3 rounded-2xl text-sm font-bold text-white shadow-md transition-all hover:opacity-90"
              style={{ background: 'linear-gradient(135deg, #8B5E3C, #6D3A5D)' }}
            >
              Enregistrer
            </button>
          </div>
        )}

      </div>
    </div>
  );
}

export function ProfilePage({ onNavigate }: ProfilePageProps) {
  const [showPersonalInfo, setShowPersonalInfo] = useState(false);

  if (showPersonalInfo) {
    return (
      <>
        <PersonalInfoPage onBack={() => setShowPersonalInfo(false)} />
        <MobileNav currentPage="profile" onNavigate={onNavigate} />
      </>
    );
  }

  return (
    <div className="min-h-screen bg-background pb-20 md:pb-8">
      <div className="max-w-4xl mx-auto px-4 py-8 space-y-6">
        {/* Hero profil */}
        <div className="rounded-3xl p-8 text-white relative overflow-hidden shadow-md" style={{ background: 'linear-gradient(135deg, #8B5E3C, #6D3A5D)' }}>
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
            <Button variant="outline" className="w-full bg-white/10 backdrop-blur-sm border-white/30 text-white hover:bg-white/20" onClick={() => setShowPersonalInfo(true)}>
              <Edit3 className="w-4 h-4" />
              Modifier le profil
            </Button>
          </div>
        </div>

        {/* Stats */}
        <Card>
          <div className="flex items-center justify-around">
            {[
              { icon: BookOpen, value: '12', label: 'Manuscrits' },
              { icon: Feather, value: '248K', label: 'Mots' },
              { icon: Clock, value: '456', label: 'Heures' },
              { icon: Award, value: '8', label: 'Prix' },
            ].map(({ icon: Icon, value, label }) => (
              <div key={label} className="text-center">
                <Icon className="w-5 h-5 text-muted-foreground mx-auto mb-2" />
                <p className="text-2xl font-bold text-foreground">{value}</p>
                <p className="text-xs text-muted-foreground mt-1">{label}</p>
              </div>
            ))}
          </div>
        </Card>

        {/* Bio */}
        <div>
          <h2 className="text-lg font-bold text-foreground mb-3">À propos</h2>
          <Card>
            <p className="text-sm text-muted-foreground leading-relaxed">
              Passionné d'écriture depuis mon plus jeune âge, je crée des mondes où la magie rencontre l'émotion.
            </p>
          </Card>
        </div>

        {/* Paramètres */}
        <div className="space-y-3">
          <h2 className="text-lg font-bold text-foreground">Paramètres</h2>

          {[
            { icon: User, label: 'Informations personnelles', sub: 'Nom, email, photo de profil', bg: 'rgba(139,94,60,0.1)', color: '#8B5E3C', action: () => setShowPersonalInfo(true) },
            { icon: Bell, label: 'Notifications', sub: 'Gérer vos préférences', bg: 'rgba(109,58,93,0.1)', color: '#6D3A5D', action: () => {} },
            { icon: Sparkles, label: 'Assistant Mukeme', sub: 'Configurer votre IA', bg: 'rgba(109,58,93,0.1)', color: '#6D3A5D', action: () => onNavigate('mukeme') },
            { icon: Shield, label: 'Confidentialité & Sécurité', sub: 'Mot de passe, visibilité', bg: 'rgba(139,94,60,0.1)', color: '#8B5E3C', action: () => {} },
            { icon: Settings, label: 'Préférences', sub: 'Langue, thème et paramètres', bg: 'rgba(107,107,107,0.1)', color: '#6B6B6B', action: () => {} },
          ].map(({ icon: Icon, label, sub, bg, color, action }) => (
            <Card key={label} hover className="cursor-pointer" onClick={action}>
              <div className="flex items-center gap-4">
                <div className="w-11 h-11 rounded-xl flex items-center justify-center shrink-0" style={{ backgroundColor: bg }}>
                  <Icon className="w-5 h-5" style={{ color }} />
                </div>
                <div className="flex-1">
                  <h3 className="font-semibold text-foreground">{label}</h3>
                  <p className="text-sm text-muted-foreground">{sub}</p>
                </div>
                <ChevronRight className="w-4 h-4 text-muted-foreground" />
              </div>
            </Card>
          ))}
        </div>

        {/* Déconnexion */}
        <div className="pt-2">
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
