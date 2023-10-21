import React from 'react';
import ExpandableContent from '../ExpandableContent';
import * as Onboarding from '../UtilityComponents';
import assets from '../cdn-assets';

const LocateMenuBarIcon: React.FC = () => (
  <Onboarding.Centered>
    <Onboarding.Heading>Find the menu bar icon</Onboarding.Heading>
    <Onboarding.Text className="mt-4 mb-3 max-w-2xl" centered>
      From now on, you’ll click the <b>menu bar icon</b> whenever you or your child needs
      to <em>interact with the Gertrude app.</em>
    </Onboarding.Text>
    <Onboarding.Text className="mb-6 max-w-2xl" centered>
      Look up in the top right corner of your screen to find it, and give it a click.
    </Onboarding.Text>
    <ExpandableContent
      asset={assets.img(`locate-menubar-icon.gif`)}
      lessRounded
      showInstructions={false}
      width={798 / 1.9}
      height={600 / 1.9}
    />
    <Onboarding.PrimaryButton
      icon="fa-solid fa-arrow-right"
      className="mt-6 translate-y-2"
    >
      Found it, next
    </Onboarding.PrimaryButton>
  </Onboarding.Centered>
);

export default LocateMenuBarIcon;
