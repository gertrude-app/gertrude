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
      <Onboarding.Text className="mt-4 mb-8 px-6" centered>
        In order to use Gertrude, you’ll <b>need an account.</b> It’s free to try for 60
        days, with <span className="underline">no credit card</span> required. Did you
        already create your Gertrude account?
      </Onboarding.Text>
      <Onboarding.ButtonGroup
        primary="Yes, I have a Gertrude account"
        secondary={{ text: `I don’t have an account...` }}
        emit={emit}
        direction="row"
      />
    </div>
  </Onboarding.Centered>
);

export default ConfirmGertrudeAccount;
