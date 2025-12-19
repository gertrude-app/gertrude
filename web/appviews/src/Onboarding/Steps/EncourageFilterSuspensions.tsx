import React from 'react';
import ExpandableContent from '../ExpandableContent';
import * as Onboarding from '../UtilityComponents';
import assets from '../cdn-assets';

const EncourageFilterSuspensions: React.FC = () => (
  <Onboarding.Centered direction="row" className="space-x-12">
    <ExpandableContent
      className="!ml-0"
      asset={assets.img(`encourage-filter-suspensions`)}
      width={800 / 2.3}
      height={600 / 2.3}
      lessRounded
    />
    <div className="flex flex-col !mr-0">
      <Onboarding.Heading>Start in “Easy Mode”</Onboarding.Heading>
      <Onboarding.Text className="max-w-2xl mt-4 mb-4">
        While you work on getting websites and apps unblocked, feel free to use{` `}
        <b>lots of temporary filter suspensions</b> to simplify the first few days.
        Especially <em>if your kids are older</em> and need to do lots of work online,
        right away.
      </Onboarding.Text>
      <Onboarding.Text className="max-w-2xl-4 mb-8">
        Keep screenshot monitoring enabled, and let your child know you’ll be able to see
        what they do.
      </Onboarding.Text>
      <Onboarding.PrimaryButton icon="fa-solid fa-arrow-right">
        Got it
      </Onboarding.PrimaryButton>
    </div>
  </Onboarding.Centered>
);

export default EncourageFilterSuspensions;
