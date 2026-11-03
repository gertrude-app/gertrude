import { AppIcon, Button, Card, HStack, Text, VStack } from '@gertrude/ui';
import { ArrowRightIcon, PencilIcon } from 'lucide-react';
import React from 'react';
import {
  type SetupApp,
  getAppSetupSteps,
  personSetupStep,
} from '#/components/onboarding/setupApps';

export interface PeopleGettingStartedProps {
  selectedApps: SetupApp[];
  onAddPerson: () => void;
  onChangeApps: () => void;
}

const PeopleGettingStarted: React.FC<PeopleGettingStartedProps> = ({
  selectedApps,
  onAddPerson,
  onChangeApps,
}) => {
  const remainingSteps = getAppSetupSteps(selectedApps);

  return (
    <section aria-label="Getting started" className="w-full text-left">
      <ol aria-label="Getting started checklist" className="space-y-3">
        <Card
          as="li"
          preset="big"
          padding={0}
          aria-current="step"
          className="overflow-hidden rounded-[21px] shadow-sm"
        >
          <Card.Body padding={2.5} className="pb-4">
            <HStack align="start" gap={3}>
              <span
                aria-hidden="true"
                className="flex size-5 shrink-0 items-center justify-center rounded-full bg-violet-500 text-xs font-medium text-white"
              >
                1
              </span>
              <VStack gap={1.5} className="min-w-0 flex-grow">
                <Text as="h2" variant="bodyLargeStrong">
                  {personSetupStep.title}
                </Text>
                <Text as="p" variant="bodySubtle" className="leading-5">
                  {personSetupStep.description}
                </Text>
              </VStack>
            </HStack>
          </Card.Body>
          <Card.Footer className="flex justify-end p-2.5!">
            <Button
              type="button"
              variant="primary"
              size="medium"
              icon={ArrowRightIcon}
              iconPosition="right"
              onClick={onAddPerson}
              className="rounded-[10px]!"
            >
              Add a person
            </Button>
          </Card.Footer>
        </Card>

        {remainingSteps.map((step, index) => (
          <Card
            key={step.id}
            as="li"
            preset="big"
            padding={0}
            className="flex overflow-hidden rounded-[21px] shadow-sm"
          >
            <HStack align="start" gap={3} className="min-w-0 flex-grow p-2.5">
              <span
                aria-hidden="true"
                className="flex size-5 shrink-0 items-center justify-center rounded-full bg-stone-100 text-xs text-stone-600"
              >
                {index + 2}
              </span>
              <VStack gap={1} className="min-w-0 flex-grow">
                <Text as="h2" variant="bodyStrong">
                  {step.title}
                </Text>
                <Text as="p" variant="captionMuted" className="leading-5">
                  {step.description}
                </Text>
              </VStack>
            </HStack>
            {step.icon && (
              <div className="flex w-18 shrink-0 items-center justify-center border-l border-stone-200/70 bg-stone-50">
                <AppIcon src={step.icon} />
              </div>
            )}
          </Card>
        ))}
      </ol>

      <HStack justify="between" gap={3} className="mt-4 pl-2.5">
        <Text as="p" variant="captionSubtle" className="min-w-0 leading-5">
          You can add more people or apps later.
        </Text>
        <Button
          type="button"
          variant="default"
          size="small"
          icon={PencilIcon}
          onClick={onChangeApps}
          className="shrink-0"
        >
          {selectedApps.length > 0 ? `Change apps` : `Choose apps`}
        </Button>
      </HStack>
    </section>
  );
};

export default PeopleGettingStarted;
