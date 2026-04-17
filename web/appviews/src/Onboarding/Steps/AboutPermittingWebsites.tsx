import { Button } from '@shared/components';
import cx from 'classnames';
import React, { useContext, useEffect, useState } from 'react';
import OnboardingContext from '../OnboardingContext';
import * as Onboarding from '../UtilityComponents';

const CHILDREN: { domain: string; label: string }[] = [
  { domain: `images.safesite.com`, label: `this for its images` },
  { domain: `video-service.com`, label: `this for its videos` },
  { domain: `cdn.webfonts.net`, label: `and this for its fonts` },
];

const STEP_DELAYS = [300, 3000, 1500, 1500, 1500, 3000];

type Phase = `idle` | `fadingOut` | `running` | `done`;

const FADE_MS = 500;

const AboutPermittingWebsites: React.FC = () => {
  const { emit } = useContext(OnboardingContext);
  const [step, setStep] = useState(0);
  const [phase, setPhase] = useState<Phase>(`idle`);

  useEffect(() => {
    if (phase === `fadingOut`) {
      const id = setTimeout(() => setPhase(`running`), FADE_MS);
      return () => clearTimeout(id);
    }
    if (phase !== `running`) return;
    const isLast = step >= STEP_DELAYS.length - 1;
    const delay = STEP_DELAYS[step] ?? 1000;
    const id = setTimeout(() => {
      if (isLast) {
        setPhase(`done`);
      } else {
        setStep((s) => s + 1);
      }
    }, delay);
    return () => clearTimeout(id);
  }, [step, phase]);

  const handleClick = (): void => {
    if (phase === `idle`) {
      setPhase(`fadingOut`);
    } else if (phase === `done`) {
      emit({ case: `primaryBtnClicked` });
    }
  };

  return (
    <Onboarding.Centered className="!justify-start pt-28">
      <div className="flex flex-col items-center max-w-2xl">
        <div className="flex items-center gap-4">
          <span className="w-12 h-12 rounded-2xl bg-gradient-to-br from-violet-400 to-fuchsia-500 flex items-center justify-center shadow-lg shadow-violet-200/70">
            <i className="fa-solid fa-lock-open text-white text-xl" />
          </span>
          <Onboarding.Heading>
            About permitting <em className="xunderline">websites</em>
          </Onboarding.Heading>
        </div>

        <Onboarding.Text className="mt-8 max-w-xl" centered>
          It&rsquo;s important to understand that in order to <b>permit</b> a single
          website, we often have to allow several <b>unrelated addresses</b>.
        </Onboarding.Text>

        {(phase === `idle` || phase === `fadingOut`) && (
          <Button
            type="button"
            color="secondary"
            size="large"
            onClick={handleClick}
            className={cx(
              `mt-10 transition-opacity duration-500`,
              phase === `fadingOut` ? `opacity-0 pointer-events-none` : `opacity-100`,
            )}
            tabIndex={-1}
          >
            Show me...
          </Button>
        )}

        {(phase === `running` || phase === `done`) && (
          <>
            <AnimatedDomainDiagram step={step} />
            <Button
              type="button"
              color="primary"
              size="large"
              onClick={handleClick}
              className={cx(
                `mt-10 transition-opacity duration-500`,
                phase === `done` ? `opacity-100` : `opacity-0 pointer-events-none`,
              )}
              tabIndex={-1}
            >
              Got it, next
              <i className="fa-solid fa-arrow-right ml-3" />
            </Button>
          </>
        )}
      </div>
    </Onboarding.Centered>
  );
};

const AnimatedDomainDiagram: React.FC<{ step: number }> = ({ step }) => {
  const parentVisible = step >= 1;
  const caption1Visible = step >= 1;
  const caption2Visible = step >= 2;
  const lastVisibleChildIndex = Math.min(step - 3, CHILDREN.length - 1);
  const anyChildVisible = lastVisibleChildIndex >= 0;

  return (
    <div className="mt-14 mb-4 grid grid-cols-[auto_auto] gap-x-4 content-start">
      <div
        className={cx(
          `justify-self-end self-start mt-0.5 px-5 py-2 rounded-lg border border-violet-200 bg-violet-50 shadow-sm shadow-violet-100 whitespace-nowrap text-base text-slate-700 font-medium transition-opacity duration-500 -ml-8`,
          caption1Visible ? `opacity-100` : `opacity-0`,
        )}
      >
        Suppose we want to allow this site:
      </div>
      <div className="justify-self-start flex flex-col items-start">
        <div
          className={cx(
            `inline-flex items-center gap-2.5 px-5 py-2.5 rounded-xl bg-gradient-to-br from-violet-500 to-fuchsia-500 shadow-md shadow-violet-200/70 transition-opacity duration-500`,
            parentVisible ? `opacity-100` : `opacity-0`,
          )}
        >
          <i className="fa-solid fa-globe text-white/85 text-base" />
          <span className="font-mono text-base text-white font-semibold">
            safesite.com
          </span>
        </div>
        <div
          className={cx(
            `ml-6 h-3 w-px bg-slate-300 transition-opacity duration-500`,
            anyChildVisible ? `opacity-100` : `opacity-0`,
          )}
        />
      </div>

      <div
        className={cx(
          `justify-self-end self-center px-5 py-2 rounded-lg border border-violet-200 bg-violet-50 shadow-sm shadow-violet-100 whitespace-nowrap text-base text-slate-700 font-medium transition-opacity duration-500`,
          caption2Visible ? `opacity-100` : `opacity-0`,
        )}
      >
        We might also need:
      </div>
      <div className="justify-self-start ml-6 flex flex-col">
        {CHILDREN.map((child, i) => {
          const visible = i <= lastVisibleChildIndex;
          const isCurrentLastVisible = i === lastVisibleChildIndex;
          return (
            <div key={child.domain} className="relative flex items-center h-9">
              <div
                className={cx(
                  `absolute left-0 top-0 w-px bg-slate-300 transition-opacity duration-500`,
                  isCurrentLastVisible ? `h-[18px]` : `h-full`,
                  visible ? `opacity-100` : `opacity-0`,
                )}
              />
              <div
                className={cx(
                  `absolute left-0 top-[18px] h-px w-5 bg-slate-300 transition-opacity duration-500`,
                  visible ? `opacity-100` : `opacity-0`,
                )}
              />
              <div className="ml-5 w-44 flex">
                <div
                  className={cx(
                    `inline-flex items-center gap-2 px-3 py-1.5 rounded-lg bg-white border border-slate-200 shadow-sm transition-opacity duration-500`,
                    visible ? `opacity-100` : `opacity-0`,
                  )}
                >
                  <span className="font-mono text-xs text-slate-700">{child.domain}</span>
                </div>
              </div>
              <span
                className={cx(
                  `text-sm text-emerald-600 transition-opacity duration-500`,
                  visible ? `opacity-100` : `opacity-0`,
                )}
              >
                &larr; {child.label}
              </span>
            </div>
          );
        })}
      </div>
    </div>
  );
};

export default AboutPermittingWebsites;
