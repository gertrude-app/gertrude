import React from 'react';
import LoadingDots from '#/components/ui/LoadingDots';

const SizesExample: React.FC = () => (
  <div className="grid h-full place-items-center p-8">
    <div className="flex flex-wrap items-center justify-center gap-8 text-stone-800">
      <div className="flex flex-col items-center gap-4">
        <span className="text-sm text-stone-500">Extra small</span>
        <LoadingDots size="xsmall" />
      </div>
      <div className="flex flex-col items-center gap-4">
        <span className="text-sm text-stone-500">Small</span>
        <LoadingDots size="small" />
      </div>
      <div className="flex flex-col items-center gap-4">
        <span className="text-sm text-stone-500">Medium</span>
        <LoadingDots />
      </div>
      <div className="flex flex-col items-center gap-4">
        <span className="text-sm text-stone-500">Large</span>
        <LoadingDots size="large" />
      </div>
      <div className="flex flex-col items-center gap-4 rounded-xl bg-violet-500 px-5 py-4">
        <span className="text-sm text-white/80">Inverted</span>
        <LoadingDots size="small" variant="inverted" />
      </div>
    </div>
  </div>
);

export default SizesExample;
