import { useState } from 'react';
import { Button } from '../components/Button';
import { Input } from '../components/Input';
import { Feather } from 'lucide-react';

interface SignupPageProps {
  onNavigate: (page: string) => void;
}

export function SignupPage({ onNavigate }: SignupPageProps) {
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');

  const handleSignup = () => {
    onNavigate('role-selection');
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-background px-4">
      <div className="w-full max-w-md space-y-8">
        <div className="text-center space-y-4">
          <div className="flex items-center justify-center gap-2">
            <Feather className="w-8 h-8 text-primary" strokeWidth={1.5} />
            <h1 className="text-4xl font-bold text-primary">Plumora</h1>
          </div>
          <p className="text-muted-foreground">Créez votre compte</p>
        </div>

        <div className="bg-card border border-border rounded-2xl p-8 shadow-sm space-y-6">
          <Input
            id="firstName"
            label="Prénom"
            type="text"
            placeholder="Kevin"
            value={firstName}
            onChange={(e) => setFirstName(e.target.value)}
          />

          <Input
            id="lastName"
            label="Nom"
            type="text"
            placeholder="Martin"
            value={lastName}
            onChange={(e) => setLastName(e.target.value)}
          />

          <Input
            id="email"
            label="Email"
            type="email"
            placeholder="votre@email.com"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
          />

          <Input
            id="password"
            label="Mot de passe"
            type="password"
            placeholder="••••••••"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />

          <Input
            id="confirmPassword"
            label="Confirmer le mot de passe"
            type="password"
            placeholder="••••••••"
            value={confirmPassword}
            onChange={(e) => setConfirmPassword(e.target.value)}
          />

          <Button className="w-full" size="lg" onClick={handleSignup}>
            Créer mon compte
          </Button>

          <div className="text-center text-sm text-muted-foreground">
            Déjà un compte ?{' '}
            <button
              onClick={() => onNavigate('login')}
              className="text-primary hover:underline"
            >
              Se connecter
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
