import { FullscreenGradientBg, GradientIcon } from '@dash/components';
import { Button } from '@shared/components';
import React from 'react';

const LinkExpired: React.FC = () => (
  <FullscreenGradientBg>
    <div className="bg-white font-sans max-w-lg rounded-2xl mx-4 pt-8 pl-7 pr-8 pb-6 shadow-lg flex flex-col sm:flex-row space-y-4 sm:space-y-0 sm:space-x-4 relative items-center sm:items-start">
      <GradientIcon icon="clock" size="medium" />
      <div className="flex flex-col items-center sm:items-start">
        <h1 className="text-lg font-semibold text-slate-900">Link expired</h1>
        <p className="text-center sm:text-left text-slate-500 mt-1">
          This link has expired. Gertrude SMS short links are only valid for 7 days.
        </p>
        <Button color="secondary" type="link" to="/" className="mt-5 self-end">
          Go to dashboard &rarr;
        </Button>
      </div>
    </div>
  </FullscreenGradientBg>
);

export default LinkExpired;
