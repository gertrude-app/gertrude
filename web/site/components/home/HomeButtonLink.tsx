import React from 'react';

interface HomeButtonLinkProps extends React.ComponentProps<`a`> {
  inverted?: boolean;
  size?: `header` | `hero`;
  variant: `primary` | `secondary`;
}

const HomeButtonLink: React.FC<HomeButtonLinkProps> = ({
  children,
  className = ``,
  inverted = false,
  size = `header`,
  variant,
  ...props
}) => (
  <a
    {...props}
    className={`${baseClasses} ${
      inverted
        ? variant === `primary`
          ? invertedPrimaryClasses
          : invertedSecondaryClasses
        : variantClasses[variant]
    } ${sizeClasses[size]} ${className}`}
  >
    {children}
  </a>
);

export default HomeButtonLink;

const baseClasses = `inline-flex items-center justify-center gap-1.5 rounded-full border font-[450] outline-none transition-[border-color,box-shadow,background-color,color] duration-150 focus-visible:ring-2 focus-visible:ring-offset-2`;

const variantClasses = {
  primary: `border-violet-800 bg-violet-500 text-white shadow-sm shadow-violet-500/30 hover:border-violet-900 hover:bg-violet-600 hover:shadow-violet-500/50 focus-visible:ring-violet-400/70`,
  secondary: `border-stone-300/80 bg-white text-stone-800 shadow-sm shadow-stone-300/30 hover:border-stone-400/80 hover:shadow-stone-300/60 focus-visible:ring-stone-400/70`,
};

const invertedPrimaryClasses = `border-violet-400 bg-violet-500 text-white shadow-sm shadow-violet-950/30 hover:border-violet-300 hover:bg-violet-400 hover:shadow-violet-950/40 focus-visible:ring-violet-300/70 focus-visible:ring-offset-stone-950`;

const invertedSecondaryClasses = `border-white/15 bg-white/10 text-stone-100 shadow-sm shadow-black/20 hover:border-white/25 hover:bg-white/15 hover:shadow-black/30 focus-visible:ring-white/40 focus-visible:ring-offset-stone-950`;

const sizeClasses = {
  header: `h-9 px-3 text-sm`,
  hero: `h-12 px-5 text-base`,
};
