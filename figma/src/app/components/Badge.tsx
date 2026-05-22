import { HTMLAttributes, forwardRef } from 'react';
import { clsx } from 'clsx';

interface BadgeProps extends HTMLAttributes<HTMLSpanElement> {
  variant?: 'draft' | 'beta' | 'ready' | 'published' | 'rejected' | 'correcting';
}

export const Badge = forwardRef<HTMLSpanElement, BadgeProps>(
  ({ className, variant = 'draft', children, ...props }, ref) => {
    const variantStyles = {
      draft: 'bg-[#F1E8D8] text-[#8E7345]',
      beta: 'bg-[#E6EFE4] text-[#5F7A5A]',
      correcting: 'bg-[#F8E6D2] text-[#A4683E]',
      ready: 'bg-[#E6F0E7] text-[#4F7A56]',
      published: 'bg-[#EADFCF] text-[#7A5E2F]',
      rejected: 'bg-[#F7E0DC] text-[#A85B50]',
    };

    return (
      <span
        ref={ref}
        className={clsx(
          'inline-flex items-center px-3 py-1 rounded-full text-xs font-medium',
          variantStyles[variant],
          className
        )}
        {...props}
      >
        {children}
      </span>
    );
  }
);

Badge.displayName = 'Badge';
