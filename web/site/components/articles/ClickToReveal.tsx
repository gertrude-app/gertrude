import { ChevronDownIcon, WrenchIcon } from 'lucide-react';
import React from 'react';

type Props = {
  title: string;
  children: React.ReactNode;
};

const ClickToReveal: React.FC<Props> = ({ title, children }) => (
  <details className="group my-10 overflow-hidden rounded-[24px] border border-white bg-white/50 shadow-md shadow-violet-950/5">
    <summary className="flex cursor-pointer list-none items-center justify-between gap-4 px-5 py-5 transition-colors duration-200 marker:content-none hover:bg-white/40 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-violet-400 xs:px-6 [&::-webkit-details-marker]:hidden">
      <span className="flex min-w-0 items-center gap-3">
        <WrenchIcon className="size-5 shrink-0 text-violet-600" strokeWidth={1.9} />
        <span className="text-lg font-semibold leading-6 tracking-tight text-stone-950 xs:text-xl">
          {title}
        </span>
      </span>
      <ChevronDownIcon
        className="size-5 shrink-0 text-stone-500 transition-[color,transform] duration-200 group-hover:text-violet-700 group-open:rotate-180"
        strokeWidth={1.9}
      />
    </summary>
    <div className="border-t border-white bg-white/20 px-5 py-2 xs:px-7">{children}</div>
  </details>
);

export default ClickToReveal;
