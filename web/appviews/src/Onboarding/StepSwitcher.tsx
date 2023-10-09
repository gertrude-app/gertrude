import React, { useContext, useEffect, useState } from 'react';
import ConfettiExplosion from 'react-confetti-explosion';
import cx from 'classnames';
import type { OnboardingStep } from './onboarding-store';
import CurrentStepContext from './CurrentStepContext';
import ProgressIndicator from './ProgressIndicator';

interface Props {
  step: OnboardingStep;
  children: React.ReactNode;
}

const StepSwitcher: React.FC<Props> = ({ step, children }) => {
  const [expandBlurs, setExpandBlurs] = useState(false);
  const progressStep = (() => {
    switch (step) {
      case `welcome`:
      case `confirmGertrudeAccount`:
      case `noGertrudeAccount`:
        return 1;
      case `macosUserAccountType`:
        return 2;
      case `getChildConnectionCode`:
      case `connectChild`:
        return 3;
      case `allowNotifications_start`:
      case `allowNotifications_grant`:
      case `allowNotifications_failed`:
        return 4;
      case `allowScreenshots_required`:
      case `allowScreenshots_openSysSettings`:
      case `allowScreenshots_grantAndRestart`:
      case `allowScreenshots_success`:
      case `allowScreenshots_failed`:
        return 5;
      case `allowKeylogging_required`:
      case `allowKeylogging_openSysSettings`:
      case `allowKeylogging_grant`:
      case `allowKeylogging_failed`:
        return 6;
      default:
        return 7;
    }
  })();

  useEffect(() => {
    if (step === `finish`) {
      setTimeout(() => {
        setExpandBlurs(true);
      }, 500);
    }
  }, [step]);

  return (
    <CurrentStepContext.Provider value={step}>
      <div className="w-screen h-screen relative overflow-hidden bg-slate-50">
        <div
          className={cx(
            `absolute -left-96 -bottom-72 w-152 h-152 [background:radial-gradient(#8b5cf656_0%,transparent_70%,transparent)] transition-transform duration-[2s] ease-in`,
            expandBlurs && `scale-[350%]`,
          )}
        />
        <div
          className={cx(
            `absolute left-0 -bottom-96 w-152 h-152 [background:radial-gradient(#d946ef56_0%,transparent_70%,transparent)] transition-transform duration-[2s] ease-in`,
            expandBlurs && `scale-[350%]`,
          )}
        />
        <div
          className={cx(
            `absolute -right-80 -bottom-80 w-152 h-152 [background:radial-gradient(#8b5cf656_0%,transparent_70%,transparent)] transition-transform duration-[2s] ease-in`,
            expandBlurs && `scale-[350%]`,
          )}
        />
        {children}
        <div
          className={cx(
            `absolute top-0 left-0 w-full p-5 flex justify-center items-center transition-[opacity,transform] duration-500`,
            (step === `welcome` || step === `finish`) && `-translate-y-16 opacity-0`,
          )}
        >
          <ProgressIndicator step={progressStep} />
        </div>
      </div>
    </CurrentStepContext.Provider>
  );
};

export default StepSwitcher;

interface OnboardingStepProps {
  step: OnboardingStep;
  component: React.ReactNode;
  confetti?: boolean;
  confettiDeps?: any[];
}

export const OnboardingPage: React.FC<OnboardingStepProps> = ({
  step,
  component,
  confetti,
  confettiDeps,
}) => {
  const currentStep = useContext(CurrentStepContext);
  const [hasBeenVisited, setHasBeenVisited] = useState(false);
  const [showConfetti, setShowConfetti] = useState(false);

  React.useEffect(() => {
    if (step === currentStep) {
      setHasBeenVisited(true);
      if (confetti) {
        setTimeout(() => {
          setShowConfetti(true);
        }, 1000);
      }
    }
  }, [step, currentStep, confettiDeps, confetti]);

  return (
    <div
      className={cx(
        step === currentStep
          ? `left-0 z-10`
          : hasBeenVisited
          ? `left-[-100%] opacity-0`
          : `left-full opacity-0`,
        `absolute w-full h-full top-0 transition-[opacity,left] duration-700`,
      )}
    >
      {showConfetti && (
        <ConfettiExplosion
          particleCount={50}
          colors={[`#8b5cf6`, `#d946ef`, `#6366f1`]}
          className="left-[50vw] top-0 absolute"
        />
      )}
      {component}
    </div>
  );
};
