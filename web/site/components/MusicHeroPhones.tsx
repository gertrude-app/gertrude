import cx from 'classnames';
import React from 'react';

const MusicHeroPhones: React.FC<{ className?: string }> = ({ className }) => (
  <div className={cx(`relative mx-auto aspect-[10/11]`, className)}>
    <div className="absolute inset-[12%] rounded-full bg-gradient-to-br from-violet-600/35 to-fuchsia-500/25 blur-3xl" />
    <div className="absolute inset-0 flex items-start justify-center gap-[5%]">
      <img
        src="/music/iphone-library-secondary.png"
        alt="Gertrude Music Now Playing on iPhone"
        width={1091}
        height={2473}
        className="mt-[3%] h-[78%] w-auto shrink-0 drop-shadow-[0_35px_65px_rgba(0,0,0,0.65)]"
      />
      <img
        src="/music/iphone-library-primary.png"
        alt="Gertrude Music library on iPhone"
        width={1083}
        height={2497}
        className="mt-[10%] h-[78%] w-auto shrink-0 drop-shadow-[0_35px_65px_rgba(0,0,0,0.65)]"
      />
    </div>
  </div>
);

export default MusicHeroPhones;
