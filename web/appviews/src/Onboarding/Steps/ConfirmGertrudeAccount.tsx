import React from 'react';
import type { AppEvent } from '../onboarding-store';
import * as Onboarding from '../UtilityComponents';

interface Props {
  emit: (event: AppEvent) => unknown;
}

const ConfirmGertrudeAccount: React.FC<Props> = ({ emit }) => (
  <Onboarding.Centered>
    <div className="flex flex-col justify-center items-center p-12 rounded-3xl shadow-lg bg-white shadow-slate-300/30">
      <Onboarding.Heading>Gertrude Account</Onboarding.Heading>
      <Onboarding.Text className="mt-4 mb-8" centered>
        In order to use Gertrude, you'll <b>need an account.</b> It's free to try for 60
        days, no credit card required. Do you already have a Gertrude account?
      </Onboarding.Text>
      <Onboarding.ButtonGroup
        primary={{ text: `I have a Gertrude account`, icon: `fa-solid fa-arrow-right` }}
        secondary={{ text: `I don't have an account` }}
        emit={emit}
        direction="row"
      />
    </div>
  </Onboarding.Centered>
);

export default ConfirmGertrudeAccount;
