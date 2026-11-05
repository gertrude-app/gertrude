import { Button, Card, HStack, Text, VStack, useSidebarContext } from '@gertrude/ui';
import cx from 'clsx';
import { ArrowRightIcon, CheckIcon, SettingsIcon } from 'lucide-react';
import React from 'react';
import {
  type SetupApp,
  type SetupStepId,
  getChecklistSteps,
} from '#/components/onboarding/setupApps';

interface Props {
  selectedApps: SetupApp[];
  includeNotifications?: boolean;
  completedSteps: SetupStepId[];
  onSelectStep: (step: SetupStepId) => void;
  onChangeApps?: () => void;
  defaultExpanded?: boolean;
}

const SetupChecklist: React.FC<Props> = ({
  selectedApps,
  includeNotifications,
  completedSteps,
  onSelectStep,
  onChangeApps,
  defaultExpanded = true,
}) => {
  const { close } = useSidebarContext();
  const selectStep = (step: SetupStepId): void => {
    close();
    onSelectStep(step);
  };
  const headingId = React.useId();
  const listId = React.useId();
  const [expanded, setExpanded] = React.useState(defaultExpanded);
  const steps = getChecklistSteps(selectedApps, includeNotifications);
  const completedCount = steps.filter((step) => completedSteps.includes(step.id)).length;
  const currentStep = steps.find((step) => !completedSteps.includes(step.id));

  return (
    <Card
      as="section"
      aria-labelledby={headingId}
      padding={0}
      className="-mx-2.5 overflow-hidden shadow-sm"
    >
      <div className="relative">
        <button
          type="button"
          aria-expanded={expanded}
          aria-controls={listId}
          aria-labelledby={headingId}
          onClick={() => setExpanded(!expanded)}
          className="absolute inset-0 cursor-pointer rounded-t-[inherit] outline-none transition-colors duration-100 hover:bg-stone-50 focus-visible:bg-stone-50"
        />
        <VStack gap={2} className="pointer-events-none relative px-2.5 pt-2.5 pb-2.5">
          <HStack justify="between" gap={2} className="w-full">
            <Text id={headingId} variant="captionStrong">
              Getting started
            </Text>
            <HStack gap={1}>
              <Text variant="captionMuted">
                {completedCount} of {steps.length}
              </Text>
              {onChangeApps && (
                <button
                  type="button"
                  aria-label="Change apps"
                  title="Change apps"
                  onClick={() => {
                    close();
                    onChangeApps();
                  }}
                  className="pointer-events-auto -my-1.5 -mr-1.5 flex size-7 cursor-pointer items-center justify-center rounded-[7px] text-stone-400 outline-none transition-colors duration-100 hover:bg-stone-200/70 hover:text-stone-700 focus-visible:ring-2 focus-visible:ring-violet-300"
                >
                  <SettingsIcon aria-hidden="true" className="size-3.5" />
                </button>
              )}
            </HStack>
          </HStack>
          <span
            role="progressbar"
            aria-label="Setup progress"
            aria-valuemin={0}
            aria-valuemax={steps.length}
            aria-valuenow={completedCount}
            className="block h-1 w-full overflow-hidden rounded-full bg-stone-100"
          >
            <span
              className="block h-full rounded-full bg-violet-500 transition-[width] duration-300 motion-reduce:transition-none"
              style={{ width: `${(completedCount / steps.length) * 100}%` }}
            />
          </span>
        </VStack>
      </div>
      <div
        id={listId}
        inert={!expanded}
        className={cx(
          `grid transition-[grid-template-rows] duration-300 ease-[cubic-bezier(0.22,1,0.36,1)] motion-reduce:transition-none`,
          expanded ? `grid-rows-[1fr]` : `grid-rows-[0fr]`,
        )}
      >
        <div className="min-h-0 overflow-hidden">
          <ol
            className={cx(
              `flex flex-col gap-0.5 border-t border-stone-200/70 p-1 transition-[opacity,translate,filter] motion-reduce:transition-none`,
              expanded
                ? `translate-y-0 opacity-100 blur-none delay-75 duration-250 ease-out`
                : `-translate-y-1.5 opacity-0 blur-[2px] delay-0 duration-150 ease-in`,
            )}
          >
            {steps.map((step, index) => {
              const completed = completedSteps.includes(step.id);
              const current = step.id === currentStep?.id;
              const marker = (
                <span
                  aria-hidden="true"
                  className={cx(
                    `flex size-5 shrink-0 items-center justify-center rounded-full text-[11px]`,
                    completed && `bg-violet-100 text-violet-600`,
                    current && `bg-violet-500 font-medium text-white`,
                    !completed && !current && `bg-stone-100 text-stone-500`,
                  )}
                >
                  {completed ? (
                    <CheckIcon className="size-3" strokeWidth={3} />
                  ) : (
                    index + 1
                  )}
                </span>
              );

              if (completed) {
                return (
                  <li key={step.id}>
                    <HStack gap={2.5} className="px-1.5 py-1.5">
                      {marker}
                      <Text
                        variant="captionMuted"
                        className="min-w-0 text-[13px] !text-stone-400 line-through"
                      >
                        <span className="sr-only">Completed: </span>
                        {step.title}
                      </Text>
                    </HStack>
                  </li>
                );
              }

              if (current) {
                return (
                  <li key={step.id} aria-current="step">
                    <HStack
                      align="start"
                      gap={2.5}
                      className={cx(
                        `bg-stone-100/70 p-1.5 pb-2.5`,
                        index === steps.length - 1
                          ? `rounded-t-2xl rounded-b-[7px]`
                          : `rounded-2xl`,
                      )}
                    >
                      {marker}
                      <VStack gap={2} className="min-w-0 flex-grow">
                        <VStack gap={0.5}>
                          <Text variant="bodyStrong" className="text-[13px] leading-5">
                            {step.title}
                          </Text>
                          {step.description && (
                            <Text variant="captionMuted" className="leading-4">
                              {step.description}
                            </Text>
                          )}
                        </VStack>
                        <Button
                          type="button"
                          variant="primary"
                          size="small"
                          icon={ArrowRightIcon}
                          iconPosition="right"
                          onClick={() => selectStep(step.id)}
                          className="self-start"
                        >
                          Continue
                        </Button>
                      </VStack>
                    </HStack>
                  </li>
                );
              }

              return (
                <li key={step.id}>
                  <button
                    type="button"
                    onClick={() => selectStep(step.id)}
                    className="flex w-full cursor-pointer items-center gap-2.5 rounded-xl px-1.5 py-1.5 text-left outline-none transition-colors duration-100 hover:bg-stone-100/70 focus-visible:ring-2 focus-visible:ring-violet-300"
                  >
                    {marker}
                    <Text variant="bodySubtle" className="min-w-0 text-[13px] leading-5">
                      {step.title}
                    </Text>
                  </button>
                </li>
              );
            })}
          </ol>
        </div>
      </div>
    </Card>
  );
};

export default SetupChecklist;
