import type { ReactNode } from 'react';
import { Home, BookOpen, Feather, Library, User, MessageSquare, Shield } from 'lucide-react';

interface AppLayoutProps {
  currentPage: string;
  onNavigate: (page: string) => void;
  children: ReactNode;
}

const NAV_ITEMS = [
  { id: 'home',             label: 'Tableau de bord', icon: Home },
  { id: 'write',            label: 'Mes manuscrits',  icon: Feather },
  { id: 'discover',         label: 'Découvrir',        icon: BookOpen },
  { id: 'library',          label: 'Bibliothèque',     icon: Library },
  { id: 'beta-tests',       label: 'Bêta-retours',     icon: MessageSquare },
  { id: 'profile',          label: 'Profil',           icon: User },
];

const BOTTOM_NAV = [
  { id: 'home',     icon: Home,     label: 'Accueil' },
  { id: 'discover', icon: BookOpen, label: 'Découvrir' },
  { id: 'write',    icon: Feather,  label: 'Écrire' },
  { id: 'library',  icon: Library,  label: 'Bibliothèque' },
  { id: 'profile',  icon: User,     label: 'Profil' },
];

export function AppLayout({ currentPage, onNavigate, children }: AppLayoutProps) {
  return (
    <div className="flex min-h-screen bg-background">

      {/* ── Desktop sidebar ─────────────────────────────────────────── */}
      <aside
        className="hidden lg:flex flex-col fixed inset-y-0 left-0 w-60 z-30 border-r border-border"
        style={{ background: '#FFFFFF' }}
      >
        {/* Logo */}
        <div className="flex items-center gap-3 px-5 pt-6 pb-7">
          <div
            className="w-9 h-9 rounded-xl flex items-center justify-center shrink-0"
            style={{ background: 'linear-gradient(135deg, #7C5CFF, #9B6FD4)' }}
          >
            <Feather className="w-4 h-4 text-white" />
          </div>
          <span
            className="text-xl font-bold"
            style={{ fontFamily: 'var(--font-family-display)', color: '#1A1040' }}
          >
            Plumora
          </span>
        </div>

        {/* Nav items */}
        <nav className="flex-1 px-3 space-y-0.5">
          {NAV_ITEMS.map(({ id, label, icon: Icon }) => {
            const active = currentPage === id ||
              (id === 'write' && ['write', 'author-dashboard', 'create-book', 'editor', 'mobile-editor', 'royalties', 'my-book-detail-1', 'my-book-detail-2', 'my-book-detail-3'].includes(currentPage));
            return (
              <button
                key={id}
                onClick={() => onNavigate(id)}
                className="w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-left transition-all"
                style={{
                  background: active ? '#EDE9FF' : 'transparent',
                  color: active ? '#7C5CFF' : '#7167A0',
                  fontWeight: active ? 700 : 500,
                }}
                onMouseEnter={e => {
                  if (!active) (e.currentTarget as HTMLButtonElement).style.background = '#F5F3FF';
                }}
                onMouseLeave={e => {
                  if (!active) (e.currentTarget as HTMLButtonElement).style.background = 'transparent';
                }}
              >
                <Icon className="w-5 h-5 shrink-0" />
                <span className="text-sm">{label}</span>
              </button>
            );
          })}
        </nav>

        {/* Admin link */}
        <div className="px-3 pb-4 border-t border-border pt-3">
          <button
            onClick={() => onNavigate('admin')}
            className="w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-left transition-all"
            style={{ color: '#7167A0', fontWeight: 500 }}
            onMouseEnter={e => { (e.currentTarget as HTMLButtonElement).style.background = '#F5F3FF'; }}
            onMouseLeave={e => { (e.currentTarget as HTMLButtonElement).style.background = 'transparent'; }}
          >
            <Shield className="w-5 h-5 shrink-0" />
            <span className="text-sm">Administration</span>
          </button>

          {/* User card */}
          <div
            className="mt-3 flex items-center gap-3 px-3 py-3 rounded-xl"
            style={{ background: '#F5F3FF' }}
          >
            <div
              className="w-8 h-8 rounded-full flex items-center justify-center shrink-0 text-xs font-bold text-white"
              style={{ background: 'linear-gradient(135deg, #7C5CFF, #9B6FD4)' }}
            >
              KF
            </div>
            <div className="min-w-0">
              <p className="text-xs font-bold truncate" style={{ color: '#1A1040' }}>Kevin Fonkou</p>
              <p className="text-[10px] truncate" style={{ color: '#7167A0' }}>Auteur · Pro</p>
            </div>
          </div>
        </div>
      </aside>

      {/* ── Page content ────────────────────────────────────────────── */}
      <div className="flex-1 lg:ml-60">
        {children}
      </div>

      {/* ── Mobile bottom nav ───────────────────────────────────────── */}
      <nav
        className="lg:hidden fixed bottom-0 left-0 right-0 z-40 flex border-t border-border"
        style={{
          background: 'rgba(255,255,255,0.95)',
          backdropFilter: 'blur(12px)',
          paddingBottom: 'env(safe-area-inset-bottom)',
        }}
      >
        {BOTTOM_NAV.map(({ id, icon: Icon, label }) => {
          const active = currentPage === id;
          return (
            <button
              key={id}
              onClick={() => onNavigate(id)}
              className="flex-1 flex flex-col items-center gap-1 py-2.5 transition-colors relative"
              style={{ color: active ? '#7C5CFF' : '#7167A0' }}
            >
              {active && (
                <span style={{
                  position: 'absolute', top: 0, left: '50%',
                  transform: 'translateX(-50%)', width: 24, height: 3,
                  borderRadius: '0 0 4px 4px', background: '#7C5CFF',
                }} />
              )}
              <Icon className="w-5 h-5" />
              <span className="text-[10px] font-bold leading-none">{label}</span>
            </button>
          );
        })}
      </nav>
    </div>
  );
}
