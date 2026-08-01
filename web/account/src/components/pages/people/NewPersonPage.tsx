import { Banner, HStack, Input, Stack, VStack } from '@gertrude/ui';
import cx from 'clsx';
import { UserIcon } from 'lucide-react';
import React from 'react';
import type { PersonRelationship } from '#/components/types';
import CreationFlowScreen from '#/components/people/CreationFlowScreen';
import NewPersonRelationshipCard from '#/components/people/NewPersonRelationshipCard';
import { selfRelationshipUnavailableMessage } from '#/lib/people';

interface Props {
  relationship: PersonRelationship | null;
  setRelationship: (relationship: PersonRelationship) => void;
  name: string;
  setName: (name: string) => void;
  creating?: boolean;
  selfRelationshipUnavailable?: boolean;
  onFinish: () => void;
}

const NewPersonPage: React.FC<Props> = ({
  relationship,
  setRelationship,
  name,
  setName,
  creating = false,
  selfRelationshipUnavailable = false,
  onFinish,
}) => {
  const personLabel =
    relationship === `child`
      ? `your child's`
      : relationship === `peer`
        ? `this person's`
        : `your`;

  return (
    <CreationFlowScreen
      steps={[
        {
          title: `What is this person's relationship to you?`,
          element: (
            <VStack>
              <Stack
                direction={{ default: `vertical`, '@lg/main': `horizontal` }}
                gap={{ default: 2, '@lg/main': 4 }}
                className="self-stretch"
              >
                <NewPersonRelationshipCard
                  title="Your child"
                  icon={
                    <HStack align="end">
                      <UserIcon className="w-8 h-8" />
                      <UserIcon strokeWidth={2.5} className="w-5.5 h-5.5 -ml-1 mb-0.25" />
                    </HStack>
                  }
                  selected={relationship === `child`}
                  onClick={() => setRelationship(`child`)}
                />
                <NewPersonRelationshipCard
                  title="A spouse, friend, or peer"
                  icon={
                    <HStack>
                      <UserIcon className="w-8 h-8" />
                      <UserIcon className="w-8 h-8 -ml-1" />
                    </HStack>
                  }
                  selected={relationship === `peer`}
                  onClick={() => setRelationship(`peer`)}
                />
                <NewPersonRelationshipCard
                  title="Yourself"
                  icon={<UserIcon className="w-8 h-8" />}
                  selected={relationship === `self`}
                  disabled={selfRelationshipUnavailable}
                  disabledTooltip={
                    selfRelationshipUnavailable
                      ? selfRelationshipUnavailableMessage
                      : undefined
                  }
                  onClick={() => setRelationship(`self`)}
                />
              </Stack>
              <div
                aria-hidden={relationship !== `self`}
                className={cx(
                  `grid transition-[grid-template-rows] ease-out motion-reduce:transition-none motion-reduce:delay-0`,
                  relationship === `self`
                    ? `grid-rows-[1fr] duration-150 delay-0`
                    : `pointer-events-none grid-rows-[0fr] duration-100 delay-100`,
                )}
              >
                <div className="min-h-0">
                  <div
                    className={cx(
                      `pt-4 transition-[opacity,translate] duration-100 ease-out motion-reduce:transition-none motion-reduce:delay-0`,
                      relationship === `self`
                        ? `translate-y-0 opacity-100 delay-100`
                        : `-translate-y-1 opacity-0 delay-0`,
                    )}
                  >
                    <Banner variant="warning">
                      Gertrude works best when someone you trust manages your settings and
                      reviews your activity. You can continue setting it up for yourself,
                      but consider asking a trusted person to manage your account.
                    </Banner>
                  </div>
                </div>
              </div>
            </VStack>
          ),
          nextEnabled:
            relationship !== null &&
            !(relationship === `self` && selfRelationshipUnavailable),
        },
        {
          title: `What is ${personLabel} name?`,
          element: (
            <>
              <label htmlFor="new-person-name" className="sr-only">
                Name
              </label>
              <Input
                id="new-person-name"
                name="personName"
                type="text"
                value={name}
                setValue={setName}
                required
                disabled={creating}
              />
            </>
          ),
          nextEnabled: name.trim().length > 0,
        },
      ]}
      finishText="Add Person"
      onFinish={onFinish}
      finishing={creating}
    />
  );
};

export default NewPersonPage;
