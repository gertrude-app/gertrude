import { Logo } from '@shared/components';
import React from 'react';
import BgImage from '../static/chained-iphone.png';

const LockdownGuideOgImage: React.FC = () => (
  <section
    style={{
      backgroundImage: `url(${BgImage})`,
      textShadow: `0 15px 30px rgba(0,0,0,0.61), 0 5px 15px rgba(0,0,0,0.68)`,
    }}
    className="relative flex justify-center items-stretch flex-col w-[1200px] h-[627px]"
  >
    <div className="absolute inset-0 bg-gradient-to-r from-black via-violet-900/60 to-slate-800/10" />
    <div className="absolute top-10 left-14 z-10 opacity-90">
      <Logo type="inverted" size={60} textSize="text-[0px]" className="-ml-4" />
    </div>
    <div className="absolute z-30 bottom-12 left-12 text-[73px] leading-tight flex flex-col space-y-5">
      <div className="text-white text-opacity-90">
        The{` `}
        <span className="font-extrabold tracking-wide text-[82px] inline-block">
          definitive
        </span>
        {` `}
        guide to
        <b className="block text-white font-extrabold text-[118px] tracking-[7px] mb-[10px]">
          locking down
        </b>
        your kid&lsquo;s <span className="font-extrabold">iPhone</span>
      </div>
    </div>
  </section>
);

export default LockdownGuideOgImage;
