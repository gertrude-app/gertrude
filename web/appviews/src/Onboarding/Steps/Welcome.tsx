import React from 'react';
import type { AppEvent } from '../onboarding-store';

interface Props {
  emit: (event: AppEvent) => unknown;
}

const Welcome: React.FC<Props> = ({ emit }) => (
  <div>
    <h1 className="text-3xl">Gertrude Parent Setup</h1>
    <p>
      Thanks for trying Gertrude! To get started, you'll need to do a small amount of
      setup and configuration. We'll walk you through every step. It should take about 5-7
      minutes.
    </p>
    <button
      className="bg-blue-500 text-white font-bold py-2 px-4"
      onClick={() => emit({ case: `primaryBtnClicked` })}
    >
      Get started &rarr;
    </button>
  </div>
);

export default Welcome;
