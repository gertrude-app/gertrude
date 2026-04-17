import cx from 'classnames';
import React, { useEffect, useState } from 'react';

interface Props {
  shown: boolean;
  fadeInDelay?: number;
  children: (fadeIn: boolean) => React.ReactNode;
  gradient?: `violet-to-fuchsia` | `fuchsia-to-violet`;
  fadeOut?: boolean;
}

const GradientFadeInScreen: React.FC<Props> = ({
  shown,
  fadeInDelay = 400,
  gradient = `violet-to-fuchsia`,
  fadeOut = false,
  children,
}) => {
  const [fadeIn, setFadeIn] = useState(false);

  useEffect(() => {
    if (!shown) return;
    const id = setTimeout(() => setFadeIn(true), fadeInDelay);
    return () => clearTimeout(id);
  }, [shown, fadeInDelay]);

  return (
    <div className="h-full relative">
      <div
        className={cx(
          `flex flex-col justify-center items-center w-full h-full absolute left-0 top-0 transition-opacity duration-[2s]`,
          gradient === `violet-to-fuchsia`
            ? `bg-gradient-to-b from-violet-500 to-fuchsia-500`
            : `bg-gradient-to-b from-fuchsia-500 to-violet-500`,
          fadeIn && !fadeOut ? `opacity-100` : `opacity-0`,
        )}
      >
        {children(fadeIn)}
      </div>
    </div>
  );
};

export default GradientFadeInScreen;
