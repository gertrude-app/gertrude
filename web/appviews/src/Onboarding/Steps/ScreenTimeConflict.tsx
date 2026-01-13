import React, { useContext } from 'react';
import ExpandableContent from '../ExpandableContent';
import OnboardingContext from '../OnboardingContext';
import * as Onboarding from '../UtilityComponents';
import assets from '../cdn-assets';

const ScreenTimeConflict: React.FC = () => {
  const { systemSettingsName, osVersion } = useContext(OnboardingContext);
  return (
    <Onboarding.Centered direction="row" className="gap-12">
      <div className="flex flex-col items-start">
        <Onboarding.Heading>
          <i className="fas fa-exclamation-triangle text-yellow-600 mr-4" />
          Screen Time Conflict
        </Onboarding.Heading>
        <Onboarding.Text className="mt-4 max-w-xl">
          We detected that Apple’s Screen Time web filter is enabled. This prevents
          Gertrude from working, and is not necessary with Gertrude running.
        </Onboarding.Text>
        <Onboarding.Text className="mt-4 max-w-xl">
          To fix this, disable Screen Time’s <b>Content &amp; Privacy</b> section in{` `}
          {systemSettingsName}, then after finishing this welcome process, you need to
          {` `}
          <b>restart this Mac</b>.
        </Onboarding.Text>
        <Onboarding.ButtonGroup
          primary={{ text: `Fix in ${systemSettingsName}`, icon: false }}
          secondary={{ text: `Done, continue`, shadow: true }}
          className="mt-8 w-80"
        />
      </div>
      <ExpandableContent
        asset={assets.osImg(osVersion.name, `screentime-conflict`)}
        width={800 / 2.0}
        height={600 / 2.0}
      />
    </Onboarding.Centered>
  );
};

export default ScreenTimeConflict;
