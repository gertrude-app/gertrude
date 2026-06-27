import { Button } from '@gertrude/ui';
import cx from 'clsx';
import { CheckIcon, ChevronLeftIcon, ChevronRightIcon } from 'lucide-react';
import React, { useLayoutEffect, useRef, useState } from 'react';

interface Props {
  steps: Array<{
    element: React.ReactNode;
    title: string;
    nextEnabled: boolean;
  }>;
  finishText: string;
  onFinish: () => void;
}

const CreationFlowScreen: React.FC<Props> = ({ steps, finishText, onFinish }) => {
  const [currentStep, setCurrentStep] = useState(0);
  const [currentStepHeight, setCurrentStepHeight] = useState<number>();
  const stepRefs = useRef<Array<HTMLDivElement | null>>([]);

  useLayoutEffect(() => {
    const currentStepElement = stepRefs.current[currentStep];
    if (!currentStepElement) {
      return;
    }

    const updateCurrentStepHeight = (): void => {
      setCurrentStepHeight(currentStepElement.offsetHeight);
    };

    updateCurrentStepHeight();

    const resizeObserver = new ResizeObserver(updateCurrentStepHeight);
    resizeObserver.observe(currentStepElement);

    return () => resizeObserver.disconnect();
  }, [currentStep]);

  return (
    <div className="@container/main">
      <div className="min-h-screen flex flex-col gap-6 items-center relative overflow-hidden py-12 @lg:py-20 @5xl/main:py-32">
        <div className="w-full h-[150%] absolute -bottom-3/4 rounded-[100%] [background-image:radial-gradient(ellipse_at_center,oklch(60.6%_0.25_292.717_/_0.2)_0%,rgba(255,255,255,1.0)_65%),url(/dot-noise-pattern.svg),url(/bg.svg)]" />
        <span className="text-2xl font-medium relative">Add a Protected Person</span>
        <div className="flex-grow relative flex flex-col justify-center p-3 self-stretch">
          <form className="flex flex-col items-center gap-4 mx-auto w-full max-w-140">
            <div
              className="flex items-center relative w-full transition-[height] duration-200"
              style={{ height: currentStepHeight }}
            >
              {steps.map((step, i) => (
                <div
                  key={i}
                  ref={(element) => {
                    stepRefs.current[i] = element;
                  }}
                  className={cx(
                    `flex flex-col gap-4 items-center w-full absolute transition-[translate,opacity,filter] duration-200`,
                    {
                      'translate-x-20 opacity-0 pointer-events-none': currentStep < i,
                      'translate-x-0': currentStep === i,
                      '-translate-x-20 opacity-0 pointer-events-none': currentStep > i,
                    },
                  )}
                >
                  <span className="text-xl font-medium text-stone-900 text-center">
                    {step.title}
                  </span>
                  <div className="self-stretch">{step.element}</div>
                </div>
              ))}
            </div>
            <div className="flex justify-between self-stretch">
              {currentStep > 0 && (
                <Button
                  type="button"
                  onClick={() => setCurrentStep(currentStep - 1)}
                  icon={ChevronLeftIcon}
                  iconPosition="left"
                  variant="ghost"
                >
                  Back
                </Button>
              )}
              <div />
              {currentStep === steps.length - 1 ? (
                <Button
                  type="button"
                  onClick={onFinish}
                  icon={CheckIcon}
                  variant="primary"
                  disabled={!steps[currentStep].nextEnabled}
                >
                  {finishText}
                </Button>
              ) : (
                <Button
                  type="button"
                  onClick={() => setCurrentStep(currentStep + 1)}
                  icon={ChevronRightIcon}
                  iconPosition="right"
                  variant="primary"
                  disabled={!steps[currentStep].nextEnabled}
                >
                  Next
                </Button>
              )}
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default CreationFlowScreen;
