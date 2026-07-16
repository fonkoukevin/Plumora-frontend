import type { ReactNode } from 'react';
import { Bell, Feather } from 'lucide-react';

interface AppHeaderProps {
  /** Page title shown on desktop (sidebar already shows on mobile) */
  title: string;
  /** Small subtitle under the title */
  subtitle?: string;
  /** Emoji prefix for the title (desktop only) */
  emoji?: string;
  /** Gradient colors for desktop title [from, to] */
  gradient?: [string, string];
  /** Right-side extra action (e.g. "Nouvelle histoire" button) */
  action?: ReactNode;
  onNavigate: (page: string) => void;
  /** Extra content rendered below the title row (tabs, search…) */
  children?: ReactNode;
}

export function AppHeader({
  title,
  subtitle,
  emoji,
  gradient = ['#7C5CFF', '#9B6FD4'],
  action,
  onNavigate,
  children,
}: AppHeaderProps) {
  return (
    <header
      className="sticky top-0 z-30 border-b border-border bg-background/95 px-4 pt-4 pb-3"
      style={{ backdropFilter: 'blur(12px)' }}
    >
      <div className="max-w-5xl mx-auto">
        {/* Title row */}
        <div className="flex items-center justify-between gap-4">

          {/* Mobile: Plumora logo */}
          <div className="flex items-center gap-2.5 lg:hidden">
            <div
              className="w-9 h-9 rounded-xl flex items-center justify-center shrink-0"
              style={{ background: `linear-gradient(135deg, ${gradient[0]}, ${gradient[1]})` }}
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

          {/* Desktop: page title */}
          <div className="hidden lg:block">
            <h1
              className="text-2xl font-bold leading-tight"
              style={{
                fontFamily: 'var(--font-family-display)',
                background: `linear-gradient(135deg, ${gradient[0]}, ${gradient[1]})`,
                WebkitBackgroundClip: 'text',
                WebkitTextFillColor: 'transparent',
              }}
            >
              {emoji && <span style={{ WebkitTextFillColor: 'initial' }}>{emoji} </span>}
              {title}
            </h1>
            {subtitle && (
              <p className="text-xs text-muted-foreground mt-0.5">{subtitle}</p>
            )}
          </div>

          {/* Right: action + bell + avatar */}
          <div className="flex items-center gap-2">
            {action && <div className="hidden lg:flex">{action}</div>}
            <button className="w-9 h-9 rounded-xl hover:bg-muted flex items-center justify-center transition-colors relative">
              <Bell className="w-5 h-5 text-muted-foreground" />
              <span className="absolute top-2 right-2 w-2 h-2 rounded-full bg-primary" />
            </button>
            <button
              onClick={() => onNavigate('profile')}
              className="w-9 h-9 rounded-xl flex items-center justify-center shadow-md text-white text-xs font-bold shrink-0"
              style={{ background: `linear-gradient(135deg, ${gradient[0]}, ${gradient[1]})` }}
            >
              KF
            </button>
          </div>
        </div>

        {/* Extra content (tabs, search, etc.) */}
        {children && <div className="mt-3">{children}</div>}
      </div>
    </header>
  );
}
