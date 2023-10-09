import React from 'react';
import type { AppEvent } from '../onboarding-store';
import QRCode from '../QRCode';
import * as Onboarding from '../UtilityComponents';

interface Props {
  emit: (event: AppEvent) => unknown;
}

const NoGertrudeAccount: React.FC<Props> = ({ emit }) => (
  <Onboarding.Centered direction="row" className="ml-2 gap-4">
    <div>
      <Onboarding.Heading>No problem, let’s make one!</Onboarding.Heading>
      <Onboarding.Text className="mt-4 max-w-lg">
        We recommend you <b>sign up on your phone,</b> instead of this computer.{` `}
        <b>Aim your phone's camera</b> at the QR code and it will take you to the signup
        page.
      </Onboarding.Text>
      <Onboarding.Text className="mt-3 max-w-lg">
        Once you’ve verified your email, come back here and click to continue.
      </Onboarding.Text>
      <Onboarding.ButtonGroup
        primary="Done, I have a Gertrude account now"
        secondary={{ text: `I don’t want an account, quit...`, shadow: true }}
        emit={emit}
        className="mt-6 max-w-md"
      />
    </div>
    <QRCode url="gertrude.app/signup" />
  </Onboarding.Centered>
);

export default NoGertrudeAccount;
