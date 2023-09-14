import React from 'react';
import type { AppEvent } from '../onboarding-store';

interface Props {
  emit: (event: AppEvent) => unknown;
}

const ViewHealthCheck: React.FC<Props> = ({ emit }) => (
  <div>
    <h1 className="text-3xl">Admin Health Check</h1>
    <p className="my-3">
      One good thing to know about is the <b>Health Check Screen</b>. It's a quick way to
      see if everything is working correctly, and sometimes can help you fix issues.
    </p>
    <div className="my-4 bg-blue-100 p-5 rounded-lg">
      <b>Good to know:</b>
      <p>
        The health check screen will show a warning about you having <b>zero keys.</b>
        {` `}
        That's expected at this point, since you're just getting setup. 👍
      </p>
    </div>
    <img
      className="h-[280px] rounded-lg mb-4"
      src="https://gertrude.nyc3.digitaloceanspaces.com/appview-assets/onboarding/administrate.png"
      alt=""
    />
    <button
      className="bg-blue-500 text-white font-bold py-2 px-4"
      onClick={() => emit({ case: `primaryBtnClicked` })}
    >
      Done, next &rarr;
    </button>
  </div>
);

export default ViewHealthCheck;
