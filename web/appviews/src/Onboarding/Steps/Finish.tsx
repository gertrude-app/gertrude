import React from 'react';
import type { AppEvent } from '../onboarding-store';

interface Props {
  emit: (event: AppEvent) => unknown;
}

const Finish: React.FC<Props> = ({ emit }) => (
  <div>
    <h1 className="text-3xl mb-4">🎉 All Done! </h1>
    <p>If you have any questions or run into any problems you can always reach us at:</p>

    <code className="block text-4xl my-8">https://gertrude.app/contact</code>

    <button
      className="bg-blue-500 text-white font-bold py-2 px-4"
      onClick={() => emit({ case: `primaryBtnClicked` })}
    >
      Close
    </button>
  </div>
);

export default Finish;
