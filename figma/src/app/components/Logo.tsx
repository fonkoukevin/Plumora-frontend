import { Feather } from 'lucide-react';

interface LogoProps {
  size?: 'sm' | 'md' | 'lg';
  showText?: boolean;
}

export function Logo({ size = 'md', showText = true }: LogoProps) {
  const sizes = {
    sm: {
      icon: 'w-6 h-6',
      text: 'text-xl',
      container: 'gap-2',
    },
    md: {
      icon: 'w-8 h-8',
      text: 'text-2xl',
      container: 'gap-2',
    },
    lg: {
      icon: 'w-10 h-10',
      text: 'text-3xl',
      container: 'gap-3',
    },
  };

  const currentSize = sizes[size];

  return (
    <div className={`flex items-center ${currentSize.container}`}>
      <div className="relative">
        <Feather className={`${currentSize.icon} text-primary`} strokeWidth={2} />
      </div>
      {showText && (
        <h1 className={`${currentSize.text} font-bold text-foreground`}>
          Plumora
        </h1>
      )}
    </div>
  );
}
