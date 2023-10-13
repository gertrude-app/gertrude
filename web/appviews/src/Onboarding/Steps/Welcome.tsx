import React, { useEffect, useContext, useState } from 'react';
import cx from 'classnames';
import OnboardingContext from '../OnboardingContext';

const Welcome: React.FC = () => {
  const { emit } = useContext(OnboardingContext);
  const [loaded, setLoaded] = useState(false);
  const [fadeOut, setFadeOut] = useState(false);

  useEffect(() => {
    const id = setTimeout(() => setLoaded(true), 1000);
    return () => clearTimeout(id);
  }, [loaded, setLoaded]);

  return (
    <div
      className={cx(
        `h-full flex flex-col items-center justify-center bg-gradient-to-b from-fuchsia-500 to-violet-500 overflow-hidden relative transition-opacity duration-1000`,
        fadeOut && `opacity-0`,
      )}
    >
      <div
        className={cx(
          `w-screen h-[200vh] left-0 absolute bg-gradient-to-b from-white via-white to-transparent transition-[top] duration-[5s]`,
          loaded ? `-top-[200vh]` : `top-0`,
        )}
      />
      <span className={cx(`absolute text-6xl font-lato text-black`)}>
        {`Hey there!`.split(``).map((letter, index) => (
          <span
            key={letter + index}
            className={cx(
              `transition-[opacity,transform] duration-[1s] inline-block ease-in`,
              loaded && `opacity-0 -translate-y-20`,
            )}
            style={{
              transitionDelay: `${index * 50}ms`,
            }}
          >
            {letter.replace(/\s/g, `\u00A0`)}
          </span>
        ))}
      </span>
      <div
        className={cx(
          `flex flex-col justify-center items-center transition-[transform,opacity] ease-in duration-1000`,
          fadeOut && `-translate-y-8 opacity-0`,
        )}
      >
        <h1 className="text-5xl font-lato text-white">
          {`Welcome to Gertrude!`.split(``).map((letter, index) => (
            <span
              key={letter + index}
              className={cx(
                `transition-[opacity,transform] duration-[1s] inline-block ease-out`,
                !loaded && `opacity-0 translate-y-8`,
              )}
              style={{
                transitionDelay: `${index * 50 + 2500}ms`,
              }}
            >
              {letter.replace(/\s/g, `\u00A0`)}
            </span>
          ))}
        </h1>
        <p
          className={cx(
            `text-xl max-w-xl text-center text-white/80 font-medium mt-6 mb-10 transition-[opacity,transform] duration-[1s] ease-out delay-[3.5s]`,
            !loaded && `opacity-0 translate-y-8`,
          )}
        >
          We’re thrilled that you’re here. You (the parent) will need to do a small amount
          of setup and configuration to get started. We’ll walk you through every step of
          the way, and it should only take about 5-7 minutes.
        </p>
        <div
          className={cx(
            `transition-[opacity,transform] duration-[1s] ease-out delay-[4s]`,
            !loaded && `opacity-0 translate-y-8 pointer-events-none`,
          )}
        >
          <button
            className={`bg-white px-10 py-5 rounded-2xl text-xl font-semibold shadow-lg hover:opacity-90 transiton-[opacity,transform] duration-200 active:scale-[98%] active:shadow-md`}
            onClick={() => {
              setFadeOut(true);
              setTimeout(() => emit({ case: `primaryBtnClicked` }), 1000);
            }}
          >
            <span className="bg-gradient-to-r from-indigo-600 to-fuchsia-500 bg-clip-text [-webkit-background-clip:text] text-transparent flex items-center space-x-3">
              <span>Let’s do this</span>
              <i className="fa-solid fa-arrow-right" />
            </span>
          </button>
        </div>
      </div>
    </div>
  );
};

export default Welcome;
