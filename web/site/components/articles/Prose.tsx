import cx from 'classnames';
import React from 'react';

interface Props {
  children: React.ReactNode;
  className?: string;
  size?: `base` | `large`;
}

const Prose: React.FC<Props> = ({ children, className, size = `large` }) => (
  <div
    className={cx(
      `prose max-w-none text-stone-700 prose-p:leading-[1.75] prose-li:leading-[1.65]`,
      size === `large` ? `prose-lg` : `prose-base`,
      // headings
      `prose-headings:scroll-mt-28 prose-headings:font-semibold prose-headings:tracking-tight prose-headings:text-stone-950 lg:prose-headings:scroll-mt-[8.5rem]`,
      `prose-h2:mt-14 prose-h2:text-3xl prose-h3:mt-10 prose-h3:text-2xl`,
      // lead
      `prose-lead:text-stone-800`,
      // links
      `prose-a:font-semibold prose-a:text-violet-700 prose-a:decoration-violet-300 prose-a:underline-offset-2 hover:prose-a:decoration-violet-600`,
      // link underline
      `prose-a:shadow-none [--tw-prose-background:theme(colors.stone.950)]`,
      `prose-strong:text-stone-950 prose-ul:marker:text-violet-400 prose-ol:marker:text-violet-600 prose-blockquote:border-violet-300 prose-blockquote:text-stone-700`,
      `prose-code:rounded prose-code:bg-violet-950/10 prose-code:px-1 prose-code:py-0.5 prose-code:text-stone-900 prose-code:before:content-none prose-code:after:content-none`,
      // pre
      `prose-pre:rounded-xl prose-pre:bg-stone-950 prose-pre:shadow-none prose-pre:ring-1 prose-pre:ring-stone-300/10`,
      // hr
      `prose-hr:border-stone-200`,
      // em
      `prose-em:font-medium prose-em:text-stone-900`,
      className,
    )}
  >
    {children}
  </div>
);

export default Prose;
