import { Logo } from '@shared/components';
import React from 'react';

const OgImage: React.FC = () => (
  <section className="bg-gradient-to-tr from-fuchsia-500 to-violet-500 flex justify-center items-stretch flex-col w-[1200px] h-[627px]">
    <div className="h-1/2 flex items-center justify-center">
      <Logo type="inverted" size={210} textSize="text-[155px]" className="-ml-4" />
    </div>
    <div className="h-1/2 grow text-[40px] text-center flex flex-col space-y-5">
      <div className="text-white text-opacity-80 font-semibold">
        Serious parental controls for{` `}
        <b className="text-opacity-100 text-white font-extrabold">Apple computers.</b>
      </div>
      <div className="text-white text-opacity-80 font-semibold">
        <b className="text-opacity-100 text-white font-extrabold">Peace of mind</b>
        {` `}for parents.
      </div>
      <div className="text-white text-opacity-70 font-semibold text-[32px] pt-10 antialiased">
        https://gertrude.app
      </div>
    </div>
  </section>
);

export default OgImage;
