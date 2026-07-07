import { Banner, HStack, Input, Stack, VStack } from '@gertrude/ui';
import { UserIcon } from 'lucide-react';
import React from 'react';
import CreationFlowScreen from '#/components/people/CreationFlowScreen';
import NewPersonRelationshipCard from '#/components/people/NewPersonRelationshipCard';

export type PersonRelationship = `child` | `peer` | `self`;

interface Props {
  relationship: PersonRelationship | null;
  setRelationship: (relationship: PersonRelationship) => void;
  name: string;
  setName: (name: string) => void;
  onFinish: () => void;
}

const NewPersonPage: React.FC<Props> = ({
  relationship,
  setRelationship,
  name,
  setName,
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
            <VStack gap={4}>
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
                  title="A peer or accountability partner"
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
                  onClick={() => setRelationship(`self`)}
                />
              </Stack>
              {relationship === `self` && (
                <Banner variant="warning">
                  By far the best way to protect and help yourself is by having someone
                  you trust that will keep you accountable, monitor your activity, and
                  manage your internet access. Gertrude is designed to work in this way.
                  If you don't have somebody like this in your life, call the Gertrude
                  hotline at 1-800-GERTRUDE and we'll help you out.
                </Banner>
              )}
            </VStack>
          ),
          nextEnabled: relationship !== null,
        },
        {
          title: `What is ${personLabel} name?`,
          element: <Input type="text" value={name} setValue={setName} />,
          nextEnabled: name.length > 0,
        },
      ]}
      finishText="Add Person"
      onFinish={onFinish}
    />
  );
};

export default NewPersonPage;
