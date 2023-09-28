import React from 'react';
import type { AppEvent, OSGroup } from '../onboarding-store';
import ExpandableImage from '../ExpandableImage';
import Callout from '../Callout';
import * as Onboarding from '../UtilityComponents';

interface Props {
  emit: (event: AppEvent) => unknown;
  os: OSGroup;
}

const ViewHealthCheck: React.FC<Props> = ({ emit, os }) => (
  <Onboarding.Centered className="gap-12" direction="row">
    <div>
      <Onboarding.Heading>Admin health check</Onboarding.Heading>
      <Onboarding.Text className="mt-2 mb-8 max-w-2xl">
        One good thing to know about is the <b>Health Check Screen</b>. It's a quick way
        to see if everything is working correctly, and sometimes can help you fix issues.
      </Onboarding.Text>
      <Callout type="info" heading="Good to know">
        The health check screen will show a warning about you having <b>zero keys.</b>
        {` `}
        That's expected at this point, since you're just getting setup.
      </Callout>
      <Onboarding.PrimaryButton
        icon="fa-solid fa-arrow-right"
        className="mt-6"
        emit={emit}
      >
        Found it, next
      </Onboarding.PrimaryButton>
    </div>
    <ExpandableImage
      fileName="administrate.png"
      os={os}
      alt="Admin health check screen"
      width={500 * 0.75}
      height={285 * 0.75}
    />
  </Onboarding.Centered>
);

export default ViewHealthCheck;
