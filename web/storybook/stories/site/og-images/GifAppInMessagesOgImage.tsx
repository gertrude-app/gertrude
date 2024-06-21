import React from 'react';
import { Logo } from '@shared/components';
import BgImage from '../../static/messages-screenshot.png';

const GifAppMessagesOgImage: React.FC = () => (
  <section
    style={{
      backgroundImage: `url(${BgImage.src})`,
      backgroundPosition: `-50px center`,
      backgroundSize: `100%`,
      /* textShadow: `0 15px 30px rgba(0,0,0,0.61), 0 5px 15px rgba(0,0,0,0.68)`, */
    }}
    className="w-[1200px] h-[627px] relative flex flex-col justify-between items-end p-12"
  >
    <div className="w-full h-full absolute left-0 top-0 bg-gradient-to-b from-white via-transparent to-white" />
    <div className="relative text-6xl text-right flex flex-col">
      <span className="font-medium">Can't delete</span>
      <span className="text-[80px] font-black mt-4">#images app</span>
      <span className="mt-8 font-medium">from Messages in</span>
      <span className="mt-8 font-bold text-8xl">iOS 17</span>
    </div>
    <Logo className="relative" iconOnly size={100} />
  </section>
);

export default GifAppMessagesOgImage;
