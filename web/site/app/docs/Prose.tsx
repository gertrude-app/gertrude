import React from 'react';
import cx from 'classnames';

const Prose: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <div
    className={cx(
      `prose prose-invert max-w-none text-slate-400 font-docs-inter`,
      // headings
      `prose-headings:scroll-mt-28 prose-headings:font-lexend prose-headings:font-normal lg:prose-headings:scroll-mt-[8.5rem]`,
      // lead
      `prose-lead:text-slate-400`,
      // links
      `prose-a:font-semibold prose-a:text-violet-400`,
      // link underline
      `prose-a:no-underline prose-a:shadow-[inset_0_calc(-1*var(--tw-prose-underline-size,2px))_0_0_var(--tw-prose-underline,theme(colors.violet.800))] hover:prose-a:[--tw-prose-underline-size:6px] [--tw-prose-background:theme(colors.slate.900)]`,
      // pre
      `prose-pre:rounded-xl prose-pre:bg-slate-800/60 prose-pre:shadow-none prose-pre:ring-1 prose-pre:ring-slate-300/10`,
      // hr
      `prose-hr:border-slate-800`,
      // em
      `prose-em:text-slate-300 prose-em:font-medium`,
    )}
  >
    {children}
  </div>
);

export default Prose;
