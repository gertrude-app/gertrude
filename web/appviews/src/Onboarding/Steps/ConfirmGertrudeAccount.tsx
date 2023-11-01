import React from 'react';
import * as Onboarding from '../UtilityComponents';

const ConfirmGertrudeAccount: React.FC = () => (
  <Onboarding.Centered>
    <div className="flex flex-col justify-center items-center p-12 rounded-3xl shadow-lg bg-white shadow-slate-300/30">
      <Onboarding.Heading>Gertrude Parent Account</Onboarding.Heading>
      <Onboarding.Text className="mt-4 mb-8 px-6" centered>
        In order to use Gertrude, you’ll <b>need an account.</b> It’s free to try for 60
        days, with <span className="underline">no credit card</span> required. Did you
        already create your Gertrude parent account?
      </Onboarding.Text>
      <Onboarding.ButtonGroup
        primary="Yup, I have an account"
        secondary={{ text: `I don’t have an account...` }}
        direction="row"
      />
    </div>
  </Onboarding.Centered>
);

export default ConfirmGertrudeAccount;
