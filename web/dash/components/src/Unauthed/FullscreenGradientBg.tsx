import React, { useEffect } from 'react';
import cx from 'classnames';
import { env } from '@shared/components';

interface Props {
  children: React.ReactNode;
}

const FullscreenGradientBg: React.FC<Props> = ({ children }) => (
  <div className="min-h-screen flex items-center justify-center relative overflow-hidden bg-gradient-to-b from-violet-500 to-fuchsia-500">
    <ScatteredLogos />
    {children}
  </div>
);

export default FullscreenGradientBg;

interface SubtleLogoProps {
  size: number;
  angle: number;
  x: number;
  y: number;
  index: number;
}

const SubtleLogo: React.FC<SubtleLogoProps> = ({ size, x, y, angle, index }) => (
  <div
    style={{
      width: size,
      height: size,
      left: `${x}%`,
      top: `${y}%`,
      borderRadius: size / 5,
      transform: `rotate(${angle}deg)`,
    }}
    className={cx(
      index % 3 !== 0 ? `hidden sm:flex` : `flex`,
      `border-2 absolute border-dashed justify-center items-center border-white border-opacity-40`,
    )}
  >
    <div
      className="border-2 border-dashed rotate-12 border-white border-opacity-40"
      style={{
        width: size / 1.7,
        height: size / 1.7,
        borderRadius: size / 7,
      }}
    />
  </div>
);

const ScatteredLogos: React.FC = React.memo(() => {
  useEffect(() => {
    _stableRandomSeed = _SEED_INIT;
  }, []);
  return (
    <>
      {new Array(15).fill(0).map((_, index) => (
        <SubtleLogo
          key={`subtle-logo-${index}`}
          size={random() * 150 + 50}
          angle={random() * 36}
          x={random() * 150 - 2}
          y={random() * 150 - 25}
          index={index}
        />
      ))}
    </>
  );
});

function random(): number {
  return env.isScreenshotTest() ? stableRandom() : Math.random();
}

// https://stackoverflow.com/a/19303725/208770
const _SEED_INIT = 101;
let _stableRandomSeed = _SEED_INIT;
function stableRandom(): number {
  var x = Math.sin(_stableRandomSeed++) * 10000;
  return x - Math.floor(x);
}
