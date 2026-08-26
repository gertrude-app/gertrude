import React from 'react';

interface HomeButtonLinkProps extends React.ComponentProps<`a`> {
  size?: `header` | `hero`;
  variant: `primary` | `secondary`;
}

const HomeButtonLink: React.FC<HomeButtonLinkProps> = ({
  children,
  className = ``,
  size = `header`,
  variant,
  ...props
}) => (
  <a
    {...props}
    className={`${baseClasses} ${variantClasses[variant]} ${sizeClasses[size]} ${className}`}
  >
    {children}
  </a>
);

export default HomeButtonLink;

const baseClasses = `inline-flex items-center justify-center gap-1.5 rounded-full border font-[450] outline-none transition-[border-color,box-shadow,background-color] duration-150 focus-visible:ring-2 focus-visible:ring-offset-2`;

const variantClasses = {
  primary: `border-violet-800 bg-violet-500 text-white shadow-sm shadow-violet-500/30 hover:border-violet-900 hover:bg-violet-600 hover:shadow-violet-500/50 focus-visible:ring-violet-400/70`,
  secondary: `border-stone-300/80 bg-white text-stone-800 shadow-sm shadow-stone-300/30 hover:border-stone-400/80 hover:shadow-stone-300/60 focus-visible:ring-stone-400/70`,
};

const sizeClasses = {
  header: `h-9 px-3 text-sm`,
  hero: `h-12 px-5 text-base`,
};
