import React from 'react';
import ExpandableContent from '../ExpandableContent';
import * as Onboarding from '../UtilityComponents';
import assets from '../cdn-assets';

const AppNotInApplicationsDir: React.FC = () => (
  <Onboarding.Centered direction="row" className="gap-12">
    <div className="flex flex-col items-start">
      <Onboarding.Heading className="max-w-sm">
        <i className="fas fa-exclamation-triangle text-yellow-600 mr-4" />
        Wrong app location
      </Onboarding.Heading>
      <Onboarding.Text className="mt-4 max-w-2xl">
        Whoops, the app was launched from the <em>wrong location.</em> Gertrude{` `}
        <b>can’t protect your child</b> unless it is located in the main <AppDir />
        {` `}
        folder.
      </Onboarding.Text>
      <Onboarding.Text className="mt-4 max-w-2xl">
        Click to quit below, then drag the Gertrude app into the <AppDir /> folder and
        relaunch.
      </Onboarding.Text>
      <Onboarding.PrimaryButton className="mt-8">
        Quit to fix and relaunch &rarr;
      </Onboarding.PrimaryButton>
    </div>
    <ExpandableContent
      asset={assets.img(`wrong-install-dir.gif`)}
      width={800 / 2.4}
      height={600 / 2.4}
    />
  </Onboarding.Centered>
);

export default AppNotInApplicationsDir;

const AppDir: React.FC = () => <code className="text-violet-800">/Applications</code>;
