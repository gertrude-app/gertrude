import React from 'react';
import { Button } from '@shared/components';
import type { AppEvent } from '../onboarding-store';
import ExpandableImage from '../ExpandableImage';
import Callout from '../Callout';

interface Props {
  emit: (event: AppEvent) => unknown;
}

const ViewHealthCheck: React.FC<Props> = ({ emit }) => (
  <div className="h-full flex items-center p-12 gap-12">
    <div>
      <h1 className="text-3xl font-bold">Admin health check</h1>
      <p className="mt-2 text-lg text-slate-500 mb-8">
        One good thing to know about is the <b>Health Check Screen</b>. It's a quick way
        to see if everything is working correctly, and sometimes can help you fix issues.
      </p>
      <Callout type="info" heading="Good to know">
        The health check screen will show a warning about you having <b>zero keys.</b>
        {` `}
        That's expected at this point, since you're just getting setup.
      </Callout>
      <Button
        type="button"
        onClick={() => emit({ case: `primaryBtnClicked` })}
        color="primary"
        size="large"
        className="mt-4"
      >
        Found it, next
      </Button>
    </div>
    <ExpandableImage
      src="https://gertrude.nyc3.digitaloceanspaces.com/appview-assets/onboarding/administrate.png"
      alt="Admin health check screen"
      width={500 * 0.75}
      height={285 * 0.75}
    />
  </div>
);

export default ViewHealthCheck;
