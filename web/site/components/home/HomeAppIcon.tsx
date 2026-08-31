import React from 'react';

interface HomeAppIconProps {
  src: string;
  alt: string;
  className?: string;
}

const HomeAppIcon: React.FC<HomeAppIconProps> = ({ src, alt, className = `` }) => (
  <img
    src={src}
    alt={alt}
    className={`size-14 rounded-[14px] shadow-lg shadow-stone-900/10 ring-[0.5px] ring-black/10 ${className}`}
  />
);

export default HomeAppIcon;
