import React, { useState } from 'react';
import cx from 'classnames';
import type { AppEvent } from '../onboarding-store';
import QrCode from '../images/signup-qr-code.png';
import QRCode from '../QRCode';
import * as Onboarding from '../UtilityComponents';

interface Props {
  emit: (event: AppEvent) => unknown;
}

const NoGertrudeAccount: React.FC<Props> = ({ emit }) => {
  const [codeClicked, setCodeClicked] = useState(false);
  return (
    <Onboarding.Centered direction="row" className="gap-12">
      <div>
        <Onboarding.Heading>No problem, let's make one!</Onboarding.Heading>
        <Onboarding.Text className="mt-4 max-w-lg">
          It only takes a minute to create an account. We recommend you{` `}
          <b>sign up on your phone,</b> instead of this device. Aim your phone's camera at
          the QR code and it will take you to the signup page.
        </Onboarding.Text>
        <Onboarding.Text className="mt-2 max-w-lg">
          Once you've verified your email, come back here and click to continue.
        </Onboarding.Text>
        <Onboarding.ButtonGroup
          primary={{
            text: `Done, I have a gertrude account now`,
            icon: `fa-solid fa-arrow-right`,
          }}
          secondary={{ text: `Done, I have a gertrude account now`, shadow: true }}
          emit={emit}
          className="mt-6 max-w-md"
        />
      </div>
      <div className="flex flex-col justify-center items-center">
        <div
          className={cx(
            `flex flex-col items-center transition-opacity duration-500`,
            codeClicked && `opacity-0`,
          )}
        >
          <span className="text-slate-400 text-sm">Click to see url</span>
          <i className="fa-chevron-down fa-solid text-slate-400 text-sm animate-bounce mt-2 mb-1" />
        </div>
        <div onClick={() => setCodeClicked(true)}>
          <QRCode img={QrCode} url="https://gertrude.app/signup" />
        </div>
      </div>
    </Onboarding.Centered>
  );
};

export default NoGertrudeAccount;
