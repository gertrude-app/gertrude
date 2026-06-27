import { Banner, Input } from '@gertrude/ui';
import { createFileRoute } from '@tanstack/react-router';
import cx from 'clsx';
import { UserIcon } from 'lucide-react';
import React, { useState } from 'react';
import CreationFlowScreen from '#/components/CreationFlowScreen';

const NewPersonPage: React.FC = () => {
  const [relationship, setRelationship] = useState<`child` | `peer` | `self` | null>(
    null,
  );
  const [name, setName] = useState<string>(``);

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
            <div className="flex flex-col gap-4">
              <div className="flex flex-col @lg/main:flex-row gap-2 @lg/main:gap-4 self-stretch">
                <NewPersonRelationshipCard
                  title="Your child"
                  icon={
                    <div className="flex items-end">
                      <UserIcon className="w-8 h-8" />
                      <UserIcon strokeWidth={2.5} className="w-5.5 h-5.5 -ml-1 mb-0.25" />
                    </div>
                  }
                  selected={relationship === `child`}
                  onClick={() => setRelationship(`child`)}
                />
                <NewPersonRelationshipCard
                  title="A peer or accountability partner"
                  icon={
                    <div className="flex">
                      <UserIcon className="w-8 h-8" />
                      <UserIcon className="w-8 h-8 -ml-1" />
                    </div>
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
              </div>
              {relationship === `self` && (
                <Banner variant="warning">
                  By far the best way to protect and help yourself is by having someone
                  you trust that will keep you accountable, monitor your activity, and
                  manage your internet access. Gertrude is designed to work in this way.
                  If you don't have somebody like this in your life, call the Gertrude
                  hotline at 1-800-GERTRUDE and we'll help you out.
                </Banner>
              )}
            </div>
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
      onFinish={() => {
        alert(`Adding ${name}`);
      }}
    />
  );
};

const NewPersonRelationshipCard: React.FC<{
  title: string;
  icon: React.ReactNode;
  selected: boolean;
  onClick: () => void;
}> = ({ title, icon, selected, onClick }) => (
  <div
    className={cx(
      `border rounded-xl p-3 flex flex-col items-center @lg/main:w-1/3 shadow gap-2 justify-between duration-150 cursor-pointer transition-[background-color,border-color,box-shadow,scale]`,
      selected
        ? `border-violet-500/60 shadow-violet-500/30 bg-violet-50 scale-102 @lg/main:scale-105`
        : `bg-white border-stone-200 hover:border-stone-300 shadow-stone-300/30 hover:shadow-stone-300/70 scale-98`,
    )}
    onClick={onClick}
  >
    <div />
    <div className={cx(selected ? `text-violet-600` : `text-stone-500`)}>{icon}</div>
    <div />
    <span className="text-center font-medium text-stone-900 leading-5.5 text-sm select-none">
      {title}
    </span>
  </div>
);

export const Route = createFileRoute(`/_app/people/new`)({
  component: NewPersonPage,
});
