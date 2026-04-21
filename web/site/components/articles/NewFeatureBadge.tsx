import React from 'react';

const NewFeatureBadge: React.FC = () => (
  <span className="not-prose mr-1.5 align-middle">
    <span className="inline-flex items-center gap-1.5 rounded-full bg-gradient-to-r from-violet-500 to-fuchsia-500 pl-3 pr-4 py-1 text-xs font-semibold uppercase tracking-wider text-white shadow-sm ring-1 ring-white/20 align-middle relative -top-[4px]">
      <svg className="h-3 w-3" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
        <path d="M12 2l1.9 6.1L20 10l-6.1 1.9L12 18l-1.9-6.1L4 10l6.1-1.9L12 2z" />
      </svg>
      New Feature:
    </span>
  </span>
);

export default NewFeatureBadge;
