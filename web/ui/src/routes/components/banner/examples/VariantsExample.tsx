import React from 'react';
import Banner from '#/components/ui/Banner';

const VariantsExample: React.FC = () => (
  <div className="flex h-full flex-col justify-center gap-4 p-8">
    <Banner>
      Profile changes may take a few minutes to appear on the child’s device.
    </Banner>
    <Banner variant="warning">
      After changing settings, open Gertrude on the child’s device and choose{` `}
      <strong>Info → Sync Profile</strong>.
    </Banner>
    <Banner variant="error">
      This profile could not be synced. Check the device connection and try again.
    </Banner>
  </div>
);

export default VariantsExample;
