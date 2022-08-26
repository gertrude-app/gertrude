import React from 'react';
import cx from 'classnames';

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

const ScatteredLogos: React.FC = React.memo(() => (
  <>
    {new Array(15).fill(0).map((_, index) => (
      <SubtleLogo
        key={`subtle-logo-${index}`}
        size={Math.random() * 150 + 50}
        angle={Math.random() * 36}
        x={Math.random() * 150 - 2}
        y={Math.random() * 150 - 25}
        index={index}
      />
    ))}
  </>
));
