import React from 'react';
import seedrandom from 'seedrandom';

const rng = seedrandom(`moooooooooo`); // add or remove o's to change the star pattern

interface StarsProps {
  className?: string;
  quantity?: number;
}

const stars = new Array(100).fill(0).map((_) => {
  const top = rng() * 100;
  const size = rng() * 6 - (top / 100) * 5;
  return (
    <div
      style={{
        left: `${rng() * 100}%`,
        top: `${top}%`,
        width: `${size}px`,
        height: `${size}px`,
      }}
      className="absolute bg-white rounded-full"
      key={`${top}-${size}`}
    >
      {size > 4 && (
        <>
          <div
            style={{
              height: size * 4,
              width: size / 2,
              left: size / 4,
              top: -size * 1.5,
            }}
            className="absolute bg-white/40 rounded-[100%]"
          />
          <div
            style={{
              width: size * 4,
              height: size / 2,
              top: size / 4,
              left: -size * 1.5,
            }}
            className="absolute bg-white/40 rounded-[100%]"
          />
        </>
      )}
    </div>
  );
});

const Stars: React.FC<StarsProps> = ({ className, quantity }) => (
  <div className={className}>
    {stars.slice(0, quantity)}
    <div className="absolute left-0 top-0 w-full h-full backdrop-blur-[1px]" />
  </div>
);

export default Stars;
