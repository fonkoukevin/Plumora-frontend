import { useState } from 'react';
import { Button } from '../components/Button';
import { Input } from '../components/Input';
import { Feather } from 'lucide-react';

function GoogleIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 18 18" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M17.64 9.20443C17.64 8.56625 17.5827 7.95262 17.4764 7.36353H9V10.8449H13.8436C13.635 11.9699 13.0009 12.9231 12.0477 13.5613V15.8194H14.9564C16.6582 14.2526 17.64 11.9453 17.64 9.20443Z" fill="#4285F4"/>
      <path d="M8.99976 18C11.4298 18 13.467 17.1941 14.9561 15.8195L12.0475 13.5613C11.2416 14.1013 10.2107 14.4204 8.99976 14.4204C6.65567 14.4204 4.67158 12.8372 3.96385 10.71H0.957031V13.0418C2.43794 15.9831 5.48158 18 8.99976 18Z" fill="#34A853"/>
      <path d="M3.96409 10.7098C3.78409 10.1698 3.68182 9.59301 3.68182 8.99983C3.68182 8.40665 3.78409 7.82983 3.96409 7.28983V4.95801H0.957273C0.347727 6.17301 0 7.54755 0 8.99983C0 10.4521 0.347727 11.8266 0.957273 13.0416L3.96409 10.7098Z" fill="#FBBC05"/>
      <path d="M8.99976 3.57955C10.3211 3.57955 11.5075 4.03364 12.4402 4.92545L15.0216 2.34409C13.4629 0.891818 11.4257 0 8.99976 0C5.48158 0 2.43794 2.01682 0.957031 4.95818L3.96385 7.29C4.67158 5.16273 6.65567 3.57955 8.99976 3.57955Z" fill="#EA4335"/>
    </svg>
  );
}

function GitHubIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 18 18" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path fillRule="evenodd" clipRule="evenodd" d="M9 0C4.0275 0 0 4.13211 0 9.22838C0 13.3065 2.5785 16.7648 6.15375 17.9841C6.60375 18.0709 6.76875 17.7853 6.76875 17.5403C6.76875 17.3212 6.76125 16.7405 6.7575 15.9712C4.254 16.5277 3.726 14.7332 3.726 14.7332C3.3165 13.6681 2.72475 13.3832 2.72475 13.3832C1.9095 12.8111 2.78775 12.8229 2.78775 12.8229C3.6915 12.8871 4.16625 13.7737 4.16625 13.7737C4.96875 15.1847 6.273 14.777 6.7875 14.5414C6.8685 13.9443 7.10025 13.5381 7.3575 13.3082C5.35875 13.0783 3.258 12.2829 3.258 8.74642C3.258 7.73961 3.60675 6.91578 4.18425 6.27044C4.083 6.03821 3.77925 5.09739 4.263 3.82132C4.263 3.82132 5.01675 3.57407 6.738 4.76579C7.458 4.56311 8.223 4.46177 8.988 4.45847C9.753 4.46177 10.518 4.56311 11.238 4.76579C12.948 3.57407 13.7017 3.82132 13.7017 3.82132C14.1855 5.09739 13.8818 6.03821 13.7917 6.27044C14.3655 6.91578 14.7142 7.73961 14.7142 8.74642C14.7142 12.2923 12.6105 13.0745 10.608 13.3007C10.923 13.5863 11.2155 14.1438 11.2155 15.0013C11.2155 16.2403 11.2043 17.2344 11.2043 17.5403C11.2043 17.7877 11.3625 18.0756 11.8207 17.9832C15.4207 16.7609 18 13.3046 18 9.22838C18 4.13211 13.9703 0 9 0Z" fill="#24292E"/>
    </svg>
  );
}

interface LoginPageProps {
  onNavigate: (page: string) => void;
}

export function LoginPage({ onNavigate }: LoginPageProps) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  const handleLogin = () => {
    onNavigate('role-selection');
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-background px-4">
      <div className="w-full max-w-md space-y-8">
        <div className="text-center space-y-3">
          <div className="flex items-center justify-center mb-6">
            <div className="w-14 h-14 rounded-xl bg-primary flex items-center justify-center shadow-md">
              <span className="text-white font-bold text-2xl">P</span>
            </div>
          </div>
          <h1 className="text-3xl font-bold text-foreground">Bienvenue sur Plumora</h1>
          <p className="text-muted-foreground">Connectez-vous pour continuer votre aventure littéraire</p>
        </div>

        <div className="bg-card border border-border rounded-2xl p-8 shadow-lg space-y-6">
          <div className="space-y-4">
            <div>
              <label htmlFor="email" className="block text-sm font-medium text-foreground mb-2">
                Adresse email
              </label>
              <Input
                id="email"
                type="email"
                placeholder="votre@email.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
              />
            </div>

            <div>
              <label htmlFor="password" className="block text-sm font-medium text-foreground mb-2">
                Mot de passe
              </label>
              <Input
                id="password"
                type="password"
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
            </div>

            <div className="text-right">
              <button
                onClick={() => onNavigate('forgot-password')}
                className="text-sm text-secondary hover:underline"
              >
                Mot de passe oublié ?
              </button>
            </div>
          </div>

          <Button className="w-full" size="lg" onClick={handleLogin}>
            Se connecter
          </Button>

          <div className="relative">
            <div className="absolute inset-0 flex items-center">
              <div className="w-full border-t border-border"></div>
            </div>
            <div className="relative flex justify-center text-sm">
              <span className="px-4 bg-card text-muted-foreground">ou</span>
            </div>
          </div>

          <div className="space-y-3">
            <button
              onClick={() => onNavigate('role-selection')}
              className="w-full flex items-center justify-center gap-3 px-4 py-3 border-2 border-border rounded-xl hover:bg-muted transition-colors"
            >
              <GoogleIcon />
              <span className="font-medium text-foreground">Continuer avec Google</span>
            </button>

            <button
              onClick={() => onNavigate('role-selection')}
              className="w-full flex items-center justify-center gap-3 px-4 py-3 border-2 border-border rounded-xl hover:bg-muted transition-colors"
            >
              <GitHubIcon />
              <span className="font-medium text-foreground">Continuer avec GitHub</span>
            </button>
          </div>

          <div className="text-center text-sm text-muted-foreground pt-2">
            Pas encore de compte ?{' '}
            <button
              onClick={() => onNavigate('signup')}
              className="text-primary hover:underline font-medium"
            >
              S'inscrire
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
