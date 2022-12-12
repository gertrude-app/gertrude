import { Logo } from '@shared/components';
import React from 'react';

const OgImage: React.FC = () => (
  <section className="bg-gradient-to-b from-violet-500 to-fuchsia-500 flex justify-center items-stretch flex-col w-[1200px] h-[627px]">
    <div className="h-1/2 flex items-center justify-center">
      <Logo
        type="inverted"
        size={150}
        textSize="text-[155px]"
        innerColorOverride="rgb(153 74 239)"
      />
    </div>
    <div className="h-1/2 grow text-[40px] text-center flex flex-col space-y-5">
      <div className="text-white text-opacity-70 font-bold">
        Serious parental controls for{` `}
        <b className="text-opacity-90 text-white font-extrabold">Apple computers.</b>
      </div>
      <div className="text-white text-opacity-70 font-bold">
        <b className="text-opacity-90 text-white font-extrabold">Peace of mind</b>
        {` `}for parents.
      </div>
      <div className="text-white text-opacity-70 font-bold text-[32px] pt-10 antialiased">
        https://gertrude.app
      </div>
    </div>
  </section>
);

export default OgImage;
