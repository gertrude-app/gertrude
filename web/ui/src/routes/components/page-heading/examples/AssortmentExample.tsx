import PageHeading from '#/components/ui/PageHeading';
import React, { useState } from 'react';

const AssortmentExample: React.FC = () => {
  const [status, setStatus] = useState('No action yet');

  return (
    <div className="flex h-full items-center justify-center p-8">
      <div className="flex w-full max-w-4xl flex-col gap-10 rounded-2xl border border-stone-200 bg-white p-6 shadow-sm">
        <PageHeading title="Dashboard" />

        <PageHeading
          title="Sally's iPhone"
          breadcrumbs={[
            { text: 'Devices', href: '#' },
            { text: 'Mobile devices', href: '#' },
          ]}
        />

        <div>
          <PageHeading
            title="Family settings"
            subtitle="For the whole family"
            breadcrumbs={[{ text: 'Settings', href: '#' }]}
            buttons={[
              {
                text: 'Cancel',
                variant: 'secondary',
                onClick: () => setStatus('Cancelled'),
              },
              {
                text: 'Save changes',
                variant: 'primary',
                onClick: () => setStatus('Saved changes'),
              },
            ]}
          />
          <p className="mt-3 text-sm text-stone-500">{status}</p>
        </div>
      </div>
    </div>
  );
};

export default AssortmentExample;
