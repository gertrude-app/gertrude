import { ArrowRightIcon } from 'lucide-react';
import React from 'react';

interface Props {
  inputs: React.ReactNode[];
  buttons: React.ReactNode[];
  heading: string;
  subheading: string;
  bottomLink: {
    text: string;
    href: string;
  };
  bottomLinkExplanation: string;
}

const UnauthedForm: React.FC<Props> = ({
  inputs,
  buttons,
  heading,
  subheading,
  bottomLink,
  bottomLinkExplanation,
}) => (
  <form className="bg-stone-50 xs:bg-white xs:rounded-2xl xs:border border-stone-200 xs:shadow-2xl shadow-stone-500/20 xs:w-96 flex flex-col overflow-hidden min-h-screen xs:min-h-auto">
    <div className="flex flex-col p-6 gap-1 pt-20 xs:pt-6">
      <h2 className="font-semibold text-xl">{heading}</h2>
      <p className="text-sm text-stone-500 max-w-80">{subheading}</p>
    </div>
    <div className="flex flex-col xs:bg-stone-100/50 xs:border border-stone-200 p-5 gap-8 rounded-xl m-1">
      <div className="w-full flex flex-col rounded-2xl gap-3">{inputs}</div>
      <div className="flex flex-col gap-3">{buttons}</div>
    </div>
    <div className="flex-grow xs:hidden" />
    <div className="flex items-center justify-between pb-4 pt-3 px-6">
      <img src="/logo-icon.svg" alt="" className="w-6 grayscale opacity-20" />
      <div className="flex flex-col items-end">
        <span className="text-xs text-stone-500">{bottomLinkExplanation}</span>
        <a
          className="text-xs text-violet-600 font-medium flex items-center gap-0.5 group"
          href={bottomLink.href}
        >
          <span>{bottomLink.text}</span>
          <ArrowRightIcon
            className="w-3 h-3 group-hover:translate-x-0.5 transition-[translate] duration-150"
            strokeWidth={2.5}
          />
        </a>
      </div>
    </div>
  </form>
);

export default UnauthedForm;
