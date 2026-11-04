import React from 'react';

interface HomeSectionRailsProps {
  children: React.ReactNode;
  className?: string;
}

const HomeSectionRails: React.FC<HomeSectionRailsProps> = ({
  children,
  className = ``,
}) => (
  <div className="sm:px-4 md:px-6 lg:px-8 xl:px-12">
    <div className={`mx-auto max-w-7xl border-stone-200/80 sm:border-x ${className}`}>
      {children}
    </div>
  </div>
);

export default HomeSectionRails;
