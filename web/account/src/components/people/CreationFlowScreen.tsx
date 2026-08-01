import { Button, HStack, Spacer, Text, VStack } from '@gertrude/ui';
import cx from 'clsx';
import { CheckIcon, ChevronLeftIcon, ChevronRightIcon } from 'lucide-react';
import React from 'react';
import type { CreationFlowStep } from '#/components/types';

interface Props {
  steps: CreationFlowStep[];
  finishText: string;
  onFinish: () => void;
  finishing?: boolean;
  title?: string;
}

const CreationFlowScreen: React.FC<Props> = ({
  steps,
  finishText,
  onFinish,
  finishing = false,
  title = `Add a Protected Person`,
}) => {
  const [currentStep, setCurrentStep] = React.useState(0);
  const [currentStepHeight, setCurrentStepHeight] = React.useState<number>();
  const [stepHeightTransitioning, setStepHeightTransitioning] = React.useState(false);
  const stepRefs = React.useRef<Array<HTMLDivElement | null>>([]);
  const currentStepConfig = steps[currentStep];

  const goToStep = (step: number): void => {
    setStepHeightTransitioning(true);
    setCurrentStep(step);
  };

  React.useLayoutEffect(() => {
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

  if (!currentStepConfig) {
    return null;
  }

  return (
    <div className="@container/main">
      <VStack
        gap={6}
        align="center"
        className="min-h-screen relative overflow-hidden py-12 @lg:py-20 @5xl/main:py-32"
      >
        <div className="w-full h-[150%] absolute -bottom-3/4 rounded-[100%] [background-image:radial-gradient(ellipse_at_center,oklch(60.6%_0.25_292.717_/_0.2)_0%,rgba(255,255,255,1.0)_65%),url(/dot-noise-pattern.svg),url(/bg.svg)]" />
        <Text as="h1" variant="title" className="relative">
          {title}
        </Text>
        <VStack justify="center" className="flex-grow relative p-3 self-stretch">
          <VStack
            as="form"
            align="center"
            gap={4}
            className="mx-auto w-full max-w-140"
            onSubmit={(event) => {
              event.preventDefault();
              if (
                currentStep === steps.length - 1 &&
                currentStepConfig.nextEnabled &&
                !finishing
              ) {
                onFinish();
              }
            }}
          >
            <HStack
              align="center"
              className={cx(
                `relative w-full motion-reduce:transition-none`,
                stepHeightTransitioning && `transition-[height] duration-200`,
              )}
              style={{ height: currentStepHeight }}
              onTransitionEnd={(event) => {
                if (event.propertyName === `height`) {
                  setStepHeightTransitioning(false);
                }
              }}
            >
              {steps.map((step, index) => (
                <VStack
                  key={index}
                  ref={(element) => {
                    stepRefs.current[index] = element;
                  }}
                  gap={4}
                  align="center"
                  aria-hidden={currentStep !== index}
                  inert={currentStep !== index}
                  className={cx(
                    `w-full absolute transition-[translate,opacity,filter] duration-200 motion-reduce:transition-none`,
                    {
                      'translate-x-20 opacity-0 pointer-events-none': currentStep < index,
                      'translate-x-0': currentStep === index,
                      '-translate-x-20 opacity-0 pointer-events-none':
                        currentStep > index,
                    },
                  )}
                >
                  <Text as="h2" variant="title" className="text-center">
                    {step.title}
                  </Text>
                  <div className="self-stretch">{step.element}</div>
                </VStack>
              ))}
            </HStack>
            <HStack justify="between" className="self-stretch">
              {currentStep > 0 && (
                <Button
                  type="button"
                  onClick={() => goToStep(currentStep - 1)}
                  icon={ChevronLeftIcon}
                  disabled={finishing}
                  iconPosition="left"
                  variant="ghost"
                >
                  Back
                </Button>
              )}
              <Spacer />
              {currentStep === steps.length - 1 ? (
                <Button
                  type="submit"
                  icon={CheckIcon}
                  variant="primary"
                  disabled={!currentStepConfig.nextEnabled}
                  loading={finishing}
                >
                  {finishText}
                </Button>
              ) : (
                <Button
                  type="button"
                  onClick={() => goToStep(currentStep + 1)}
                  icon={ChevronRightIcon}
                  iconPosition="right"
                  variant="primary"
                  disabled={!currentStepConfig.nextEnabled}
                >
                  Next
                </Button>
              )}
            </HStack>
          </VStack>
        </VStack>
      </VStack>
    </div>
  );
};

export default CreationFlowScreen;
