import { SparklesIcon } from 'lucide-react';
import React from 'react';

const NewFeatureBadge: React.FC = () => (
  <span className="not-prose mb-2 flex items-center gap-1.5 text-sm font-semibold leading-5 tracking-normal text-violet-600">
    <SparklesIcon className="size-4" strokeWidth={1.9} aria-hidden="true" />
    New Feature
  </span>
);

export default NewFeatureBadge;
