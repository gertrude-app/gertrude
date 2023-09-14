import React from 'react';
import type { AppEvent } from '../onboarding-store';

interface Props {
  emit: (event: AppEvent) => unknown;
}

const ConfirmGertrudeAccount: React.FC<Props> = ({ emit }) => (
  <div>
    <h1 className="text-3xl">Gertrude Account</h1>
    <p className="my-3">
      In order to use Gertrude, you'll <b>need an account.</b> It's free to try for 60
      days, no credit card required. Do you already have a Gertrude account?
    </p>
    <button
      className="bg-blue-500 text-white font-bold py-2 px-4"
      onClick={() => emit({ case: `primaryBtnClicked` })}
    >
      I have a Gertrude account &rarr;
    </button>
    <button
      className="bg-gray-400 text-white font-bold py-2 px-4"
      onClick={() => emit({ case: `secondaryBtnClicked` })}
    >
      I don't have an account...
    </button>
  </div>
);

export default ConfirmGertrudeAccount;
