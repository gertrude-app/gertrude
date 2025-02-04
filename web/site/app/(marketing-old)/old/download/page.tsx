import React from 'react';
import { AppIcon } from '@shared/components';
import type { NextPage } from 'next';
import Catalina from '@/public/supported-os/macos-catalina.png';
import BigSur from '@/public/supported-os/macos-big-sur.png';
import Monterey from '@/public/supported-os/macos-monterey.png';
import Ventura from '@/public/supported-os/macos-ventura.png';
import Sonoma from '@/public/supported-os/macos-sonoma.png';
import Sequoia from '@/public/supported-os/macos-sequoia.png';
import * as seo from '@/lib/seo';

export const metadata = seo.createMetadata(
  `Download | Gertrude Internet Filter and Parental Controls`,
  seo.description(`Download Gertrude`),
);

const Download: NextPage = () => (
  <section className="bg-gradient-to-b from-violet-500 to-fuchsia-500 flex-grow flex flex-col justify-center items-center py-0 xs:py-8 sm:py-16 px-0 xs:px-6 sm:px-8 md:px-12 lg:px-16">
    <div className="bg-white/90 xs:rounded-3xl flex gap-12">
      <div className="lg+:shrink-0 lg+:max-w-2xl py-16 xs:py-8 sm:py-12 md:py-16 lg:py-20 px-6 xs:px-8 sm:px-12 md:px-16 lg:px-20 flex flex-col items-center sm:items-start">
        <h1 className="text-4xl md:text-5xl font-bold text-slate-900 text-center sm:text-left">
          Download Gertrude
        </h1>
        <p className="text-lg md:text-xl text-slate-500 mt-4 max-w-3xl text-center sm:text-left">
          The Gertrude mac app is free to download, but requires a parent account to start
          protecting a computer. If you don’t have a parent account, you can start a 21
          day trial with no credit card by{` `}
          <a className="text-fuchsia-700 hover:underline" href="/start">
            clicking here.
          </a>
        </p>
        <a
          href="https://gertrude.nyc3.digitaloceanspaces.com/releases/Gertrude.dmg"
          className="mt-8 text-2xl font-semibold text-white bg-gradient-to-r from-violet-500 to-fuchsia-500 px-6 xs:px-8 py-3 xs:py-4 rounded-3xl flex items-center gap-4 hover:shadow-lg hover:scale-[102%] transition-[transform,box-shadow] hover:shadow-fuchsia-500/20 duration-300 active:scale-[98%] active:shadow-none w-fit"
        >
          <i className="fa-solid fa-download" />
          <span>Download for macOS</span>
        </a>
        <div className="mt-16 mb-4 text-slate-400 text-lg md:text-xl bg-[#f6effd] relative w-fit sm:pl-2 sm:pr-3 sm:-ml-1 text-center">
          We currently support these operating systems:
        </div>
        <div className="grid grid-cols-2 sm:grid-cols-3 gap-2 sm:border border-violet-300/80 sm:p-4 sm:pt-6 md:pt-8 sm:-m-4 sm:-mt-7 rounded-3xl border-dashed self-stretch">
          <OperatingSystem name={`Catalina`} img={Catalina.src} />
          <OperatingSystem name={`Big Sur`} img={BigSur.src} />
          <OperatingSystem name={`Monterey`} img={Monterey.src} />
          <OperatingSystem name={`Ventura`} img={Ventura.src} />
          <OperatingSystem name={`Sonoma`} img={Sonoma.src} />
          <OperatingSystem name={`Sequoia`} img={Sequoia.src} />
        </div>
      </div>
      <div className="flex-grow lg+:flex justify-center items-center p-12 xl:p-20 bg-violet-500/10 rounded-r-3xl hidden">
        <AppIcon />
      </div>
    </div>
  </section>
);

export default Download;

interface OperatingSystemProps {
  name: string;
  img: string;
}

const OperatingSystem: React.FC<OperatingSystemProps> = ({ name, img }) => (
  <div className="flex flex-col items-center p-3 rounded-2xl bg-violet-200/50 flex-grow shrink-0">
    <img src={img} width={70} height={70} alt="macOS operating system icon" />
    <div className="mt-1 flex flex-col items-center ml-0">
      <label className="text-sm text-slate-500 -mb-1">macOS</label>
      <h3 className="font-bold text-slate-700 text-lg">{name}</h3>
    </div>
  </div>
);
