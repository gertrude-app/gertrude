import React from 'react';
import type { AppEvent } from '../onboarding-store';
import QrCode from '../images/signup-qr-code.png';

interface Props {
  emit: (event: AppEvent) => unknown;
}

const NoGertrudeAccount: React.FC<Props> = ({ emit }) => (
  <div>
    <h1 className="text-3xl">Create a Gertrude Account</h1>
    <p>
      No problem, it only takes a minute to create an account. We recommend you{` `}
      <b>sign up on your phone,</b> instead of this device. Aim your phone's camera at the
      QR code below, or go directly to{` `}
      <code>https://parents.gertrude.app/signup</code>
    </p>
    <img className="h-[200px]" src={QrCode} alt="QR code" />
    <p className="mb-3">
      Once you've verified your email, come back here and click to continue.
    </p>
    <button
      className="bg-blue-500 text-white font-bold py-2 px-4"
      onClick={() => emit({ case: `primaryBtnClicked` })}
    >
      Done, I have a Gertrude account now &rarr;
    </button>
    <button
      className="bg-gray-400 text-white font-bold py-2 px-4"
      onClick={() => emit({ case: `secondaryBtnClicked` })}
    >
      I don't want to signup, quit Gertrude...
    </button>
  </div>
);

export default NoGertrudeAccount;
