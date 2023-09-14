import React from 'react';
import type { AppEvent } from '../onboarding-store';

interface Props {
  emit: (event: AppEvent) => unknown;
}

const GetConnectionCode: React.FC<Props> = ({ emit }) => (
  <div>
    <h1 className="text-3xl">Get Connection Code</h1>
    <p className="my-3">
      On your phone, open the Gertrude parents website at{` `}
      <code>parents.gertrude.app</code>, and select the child you want to connect to.
      Then, click the <b>Get Connection Code</b> button.
    </p>
    <img
      className="h-[280px] rounded-lg mb-4"
      src="https://gertrude.nyc3.digitaloceanspaces.com/appview-assets/onboarding/get-connection-code.png"
      alt=""
    />
    <button
      className="bg-blue-500 text-white font-bold py-2 px-4"
      onClick={() => emit({ case: `primaryBtnClicked` })}
    >
      Got it, next &rarr;
    </button>
    <button
      className="bg-gray-400 text-white font-bold py-2 px-4"
      onClick={() => emit({ case: `secondaryBtnClicked` })}
    >
      I need help...
    </button>
  </div>
);

export default GetConnectionCode;
