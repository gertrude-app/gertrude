import React from 'react';
import cx from 'classnames';

const Prose: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <div
    className={cx(
      `prose max-w-none font-docs-inter text-slate-600`,
      // headings
      `prose-headings:scroll-mt-28 prose-headings:font-lexend prose-headings:font-semibold lg:prose-headings:scroll-mt-[8.5rem]`,
      // lead
      `prose-lead:text-slate-800`,
      // links
      `prose-a:font-semibold prose-a:text-violet-700`,
      // link underline
      `prose-a:no-underline prose-a:shadow-[inset_0_calc(-1*var(--tw-prose-underline-size,2px))_0_0_var(--tw-prose-underline,theme(colors.violet.400))] hover:prose-a:[--tw-prose-underline-size:6px] [--tw-prose-background:theme(colors.slate.900)]`,
      // pre
      `prose-pre:rounded-xl prose-pre:bg-slate-800/60 prose-pre:shadow-none prose-pre:ring-1 prose-pre:ring-slate-300/10`,
      // hr
      `prose-hr:border-slate-200`,
      // em
      `prose-em:text-slate-900 prose-em:font-semibold`,
    )}
  >
    {children}
  </div>
);

export default Prose;
