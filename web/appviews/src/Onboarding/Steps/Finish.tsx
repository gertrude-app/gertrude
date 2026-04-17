import cx from 'classnames';
import React, { useContext } from 'react';
import GradientFadeInScreen from '../GradientFadeInScreen';
import OnboardingContext from '../OnboardingContext';

const Finish: React.FC = () => {
  const { currentStep, emit } = useContext(OnboardingContext);
  return (
    <GradientFadeInScreen
      shown={currentStep === `finish`}
      fadeInDelay={2000}
      gradient="violet-to-fuchsia"
    >
      {(fadeIn) => (
        <>
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
            You&rsquo;re all set up! If you have any questions or run into any problems
            you can always reach us at:
          </p>
          <span
            className={cx(
              `text-4xl my-8 font-mono bg-white/50 px-8 py-4 rounded-3xl text-black/70 transition-[transform,opacity] duration-1000 delay-[1.6s] shadow-md`,
              !fadeIn && `opacity-0 translate-y-6`,
            )}
          >
            https://gertrude.app/contact
          </span>
          <div
            className={cx(
              `transition-[opacity,transform] duration-1000 delay-[1.9s]`,
              !fadeIn && `opacity-0 translate-y-6`,
            )}
          >
            <button
              tabIndex={-1}
              className="bg-white px-10 py-5 rounded-2xl text-xl font-semibold shadow-lg hover:opacity-90 transiton-[opacity,transform] duration-200 active:scale-[98%] active:shadow-md"
              onClick={() => emit({ case: `primaryBtnClicked` })}
            >
              <span className="bg-gradient-to-r from-indigo-600 to-fuchsia-500 bg-clip-text [-webkit-background-clip:text] text-transparent">
                Close
              </span>
            </button>
          </div>
        </>
      )}
    </GradientFadeInScreen>
  );
};

export default Finish;
