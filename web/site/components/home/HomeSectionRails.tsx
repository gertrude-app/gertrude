import React from 'react';

interface HomeSectionRailsProps {
  children: React.ReactNode;
  className?: string;
  inverted?: boolean;
}

const HomeSectionRails: React.FC<HomeSectionRailsProps> = ({
  children,
  className = ``,
  inverted = false,
}) => (
  <div className="sm:px-4 md:px-6 lg:px-8 xl:px-12">
    <div
      className={`mx-auto max-w-7xl sm:border-x ${inverted ? `border-white/10` : `border-stone-200/80`} ${className}`}
    >
      {children}
    </div>
  </div>
);

export default HomeSectionRails;
