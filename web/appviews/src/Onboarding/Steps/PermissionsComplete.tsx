import cx from 'classnames';
import React, { useContext, useState } from 'react';
import GradientFadeInScreen from '../GradientFadeInScreen';
import OnboardingContext from '../OnboardingContext';

const PermissionsComplete: React.FC = () => {
  const { currentStep, emit } = useContext(OnboardingContext);
  const [fadeOut, setFadeOut] = useState(false);
  return (
    <GradientFadeInScreen
      shown={currentStep === `installSysExt_success_configPivot`}
      fadeOut={fadeOut}
    >
      {(fadeIn) => (
        <>
          <h1
            className={cx(
              `text-7xl mb-6 font-bold text-white transition-[transform,opacity] duration-1000`,
              !fadeIn && `opacity-0 translate-y-6`,
            )}
          >
            Permissions done.
          </h1>
          <p
            className={cx(
              `text-3xl text-white max-w-3xl text-center transition-[transform,opacity] duration-1000 delay-[400ms] px-8`,
              !fadeIn && `opacity-0 translate-y-6`,
            )}
          >
            The rest is the easy part: a handful of choices to tell Gertrude how to
            protect your child.
          </p>
          <p
            className={cx(
              `text-xl text-white/60 max-w-2xl text-center mt-8 transition-[transform,opacity] duration-1000 delay-[700ms] px-8 italic`,
              !fadeIn && `opacity-0 translate-y-6`,
            )}
          >
            Don&rsquo;t worry&mdash;you can change any of these later from the Gertrude
            parent’s website.
          </p>
          <div
            className={cx(
              `mt-12 transition-[opacity,transform] duration-1000 delay-[1s]`,
              !fadeIn && `opacity-0 translate-y-6`,
            )}
          >
            <button
              tabIndex={-1}
              className="bg-white px-10 py-5 rounded-2xl text-xl font-semibold shadow-lg hover:opacity-90 transiton-[opacity,transform] duration-200 active:scale-[98%] active:shadow-md"
              onClick={() => {
                setFadeOut(true);
                setTimeout(() => emit({ case: `primaryBtnClicked` }), 800);
              }}
            >
              <span className="bg-gradient-to-r from-indigo-600 to-fuchsia-500 bg-clip-text [-webkit-background-clip:text] text-transparent">
                Let&rsquo;s go
              </span>
              <i className="ml-2 fa-solid fa-arrow-right text-fuchsia-500" />
            </button>
          </div>
        </>
      )}
    </GradientFadeInScreen>
  );
};

export default PermissionsComplete;
