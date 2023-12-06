import React from 'react';
import ExpandableContent from '../ExpandableContent';
import * as Onboarding from '../UtilityComponents';

const AppNotInApplicationsDir: React.FC = () => (
  <Onboarding.Centered direction="row" className="gap-12">
    <div className="flex flex-col items-start">
      <Onboarding.Heading className="max-w-sm">
        Hmm, something&apos;s not quite right...
      </Onboarding.Heading>
      <Onboarding.Text className="mt-4 max-w-2xl">
        Lorem ipsum dolor sit amet, officia excepteur ex fugiat reprehenderit enim labore
        culpa sint ad nisi Lorem pariatur mollit ex esse exercitation amet. Nisi anim
        cupidatat excepteur officia.
      </Onboarding.Text>
      <Onboarding.PrimaryButton className="mt-8">Quit Gertrude</Onboarding.PrimaryButton>
    </div>
    <ExpandableContent
      asset={{ type: `image`, url: ``, render: true }}
      width={300}
      height={200}
    />
  </Onboarding.Centered>
);

export default AppNotInApplicationsDir;
