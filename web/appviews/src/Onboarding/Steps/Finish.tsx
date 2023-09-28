import React, { useContext, useEffect, useState } from 'react';
import cx from 'classnames';
import type { AppEvent } from '../onboarding-store';
import CurrentStepContext from '../CurrentStepContext';

interface Props {
  emit: (event: AppEvent) => unknown;
}

const Finish: React.FC<Props> = ({ emit }) => {
  const [fadeIn, setFadeIn] = useState(false);
  const currentStep = useContext(CurrentStepContext);
  const shown = currentStep === `finish`;

  useEffect(() => {
    if (shown) {
      setTimeout(() => {
        setFadeIn(true);
      }, 2000);
    }
  });

  return (
    <div className="h-full relative">
      <div
        className={cx(
          `flex flex-col justify-center items-center w-full h-full absolute left-0 top-0 bg-gradient-to-b from-violet-500 to-fuchsia-500 transition-opacity duration-[2s]`,
          fadeIn ? `opacity-100` : `opacity-0`,
        )}
      >
        <h1
          className={cx(
            `text-6xl mb-4 font-bold text-white transition-[transform,opacity] duration-1000 delay-[1s]`,
            !fadeIn && `opacity-0 translate-y-6`,
          )}
        >
          All done!
        </h1>
        <p
          className={cx(
            `text-2xl text-white/70 max-w-2xl text-center transition-[transform,opacity] duration-1000 delay-[1.3s]`,
            !fadeIn && `opacity-0 translate-y-6`,
          )}
        >
          You're all set up! If you have any questions or run into any problems you can
          always reach us at:
        </p>
        <span
          className={cx(
            `text-4xl my-8 font-mono bg-white/50 px-8 py-4 rounded-3xl text-black/70 transition-[transform,opacity] duration-1000 delay-[1.6s] shadow-md`,
            !fadeIn && `opacity-0 translate-y-6`,
          )}
        >
          gertrude.app/contact
        </span>
        <div
          className={cx(
            `transition-[opacity,transform] duration-1000 delay-[1.9s]`,
            !fadeIn && `opacity-0 translate-y-6`,
          )}
        >
          <button
            className="flex items-center justify-center gap-3 bg-white px-10 py-5 rounded-2xl text-xl font-semibold shadow-lg hover:opacity-90 transiton-[opacity,transform] duration-200 active:scale-[98%] active:shadow-md"
            onClick={() => emit({ case: `primaryBtnClicked` })}
          >
            <span className="bg-gradient-to-r from-indigo-600 to-fuchsia-500 bg-clip-text [-webkit-background-clip:text] text-transparent">
              Close
            </span>
          </button>
        </div>
      </div>
    </div>
  );
};

export default Finish;
