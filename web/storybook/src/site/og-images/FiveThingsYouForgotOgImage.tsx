import React from 'react';
import { Logo } from '@shared/components';
import BgImage from '../../static/chained-iphone2.png';

const FiveThingsYouForgotOgImage: React.FC = () => (
  <section
    style={{
      backgroundImage: `url(${BgImage})`,
      backgroundPosition: `-89px -5px`,
      backgroundSize: `110%`,
      textShadow: `0 15px 30px rgba(0,0,0,0.61), 0 5px 15px rgba(0,0,0,0.68)`,
    }}
    className="relative flex justify-center items-stretch flex-col w-[1200px] h-[627px] cover"
  >
    <div className="absolute bg-rose-900 w-28 h-full" />
    <div className="absolute inset-0 left-28 right-16 bg-gradient-to-r from-rose-900 via-rose-900/40" />
    <div className="absolute top-10 left-14 z-10 opacity-90">
      <Logo type="inverted" size={60} textSize="text-[0px]" className="-ml-4" />
    </div>
    <div className="absolute z-30 bottom-16 left-12 text-[73px] leading-tight flex flex-col space-y-5">
      <div className="text-white text-opacity-80">
        The{` `}
        <span className="font-extrabold text-white text-opacity-100 tracking-wide text-[82px] inline-block">
          5 things
        </span>
        <b className="block text-white font-extrabold text-[118px] tracking-[7px] mb-[4px]">
          You Forgot
        </b>
        <span className="tracking-[2px] pr-6">locking down your kid&lsquo;s</span>
        <span className="font-extrabold text-white text-opacity-100">iPhone</span>
      </div>
    </div>
  </section>
);

export default FiveThingsYouForgotOgImage;
