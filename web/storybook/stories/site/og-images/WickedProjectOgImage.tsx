import { Logo } from '@shared/components';
import React from 'react';
import Ferris from '../../static/ferris.svg';

const WickedProjectOgImage: React.FC = () => (
  <section className="w-[1200px] h-[627px] bg-gradient-to-b from-violet-800 to-fuchsia-950 relative p-20">
    <Logo type="inverted" className="absolute right-24 top-12 scale-150" />
    <div className="flex flex-col">
      <span className="bg-gradient-to-r from-red-300 to-fuchsia-300 max-w-lg text-8xl bg-clip-text text-transparent font-semibold">
        How much <span className="text-white">porn</span> is there?
      </span>
      <span className="text-5xl text-white/50 italic mt-32">A detective story</span>
    </div>
    <img
      src={Ferris.src}
      className="w-128 absolute right-20 bottom-12 -rotate-6"
      alt="ferris detective"
    />
    <div className="absolute right-[170px] bottom-[170px] flex rotate-[-6deg]">
      <div className="rounded-b-[100px] rounded-tl-2xl bg-black w-40 h-24 px-6 py-3">
        <div className="w-12 h-4 bg-white rounded-lg" />
      </div>
      <div className="rounded-b-[100px] rounded-tr-2xl bg-black w-40 h-24 px-6 py-3">
        <div className="w-12 h-4 bg-white rounded-lg" />
      </div>
    </div>
  </section>
);

export default WickedProjectOgImage;
