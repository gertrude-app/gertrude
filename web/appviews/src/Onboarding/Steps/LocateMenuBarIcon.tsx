import React from 'react';
import type { AppEvent, OSGroup } from '../onboarding-store';
import ExpandableImage from '../ExpandableImage';
import * as Onboarding from '../UtilityComponents';

interface Props {
  emit: (event: AppEvent) => unknown;
  os: OSGroup;
}

const LocateMenuBarIcon: React.FC<Props> = ({ emit, os }) => (
  <Onboarding.Centered>
    <Onboarding.Heading>Find the menu bar icon</Onboarding.Heading>
    <Onboarding.Text className="mt-4 mb-2 max-w-2xl" centered>
      From now on, you'll click the <b>menu bar icon</b> whenever you or your child needs
      to <em>interact with the Gertrude app.</em>
    </Onboarding.Text>
    <Onboarding.Text className="mb-8 max-w-2xl" centered>
      Look up in the top right corner of your screen to find it, and give it a click.
    </Onboarding.Text>
    <ExpandableImage
      fileName="menu-bar-icon.png"
      os={os}
      alt={`Locate menu bar icon`}
      width={560}
      height={220}
    />
    <Onboarding.PrimaryButton icon="fa-solid fa-arrow-right" className="mt-8" emit={emit}>
      Found it, next
    </Onboarding.PrimaryButton>
  </Onboarding.Centered>
);

export default LocateMenuBarIcon;
