import { Badge } from '@gertrude/ui';
import React from 'react';

interface Props {
  screenshot: string;
  appIcon: string;
  heading: string;
  subheading: string;
  badges: string[];
}

const AppAd: React.FC<Props> = ({ screenshot, appIcon, heading, subheading, badges }) => (
  <div className="flex flex-col rounded-3xl border border-stone-200 shadow-md shadow-stone-300/20 bg-white">
    <div className="bg-stone-50 h-50 flex justify-center items-center m-3 relative rounded-xl">
      <img
        src={screenshot}
        alt=""
        aria-hidden="true"
        className="w-full h-full object-cover rounded-xl absolute left-0 top-0 scale-100 blur-lg opacity-70"
      />
      <img
        src={screenshot}
        alt={`${heading} screenshot`}
        className="w-full h-full object-cover border border-white rounded-xl relative"
      />
    </div>
    <div className="flex justify-center items-center h-0">
      <img
        src={appIcon}
        alt={`${heading} icon`}
        className="w-20 h-20 rounded-[22px] shadow-md shadow-stone-300/30 -translate-y-4 border border-stone-200"
      />
    </div>
    <div className="pt-10 px-8 pb-8 flex flex-col items-center">
      <div className="flex justify-center gap-2 flex-wrap">
        {badges.map((badge) => (
          <Badge key={badge} color="neutral" size="small">
            {badge}
          </Badge>
        ))}
      </div>
      <h3 className="text-lg text-stone-900 font-semibold text-center mt-2">{heading}</h3>
      <h4 className="text-sm text-stone-700 text-center">{subheading}</h4>
    </div>
  </div>
);

export default AppAd;
