import React from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { ArrowDownIcon, DownloadIcon } from 'lucide-react';
import { AppIcon } from '@shared/components';
import type { NextPage } from 'next';
import type { StaticImageData } from 'next/image';
import FancyLink from '../../../components/FancyLink';
import Computer from '../../../components/super-scroller-illustration/Computer';

import Catalina from '../../../public/supported-os/macos-catalina.png';
import BigSur from '../../../public/supported-os/macos-big-sur.png';
import Monterey from '../../../public/supported-os/macos-monterey.png';
import Ventura from '../../../public/supported-os/macos-ventura.png';
import Sonoma from '../../../public/supported-os/macos-sonoma.png';

const DownloadPage: NextPage = () => (
  <div className="flex justify-center items-center px-0 xs:px-6 sm:px-8 md:px-12 lg:px-20 py-20">
    <div className="flex flex-col xl:flex-row bg-white/90 rounded-3xl overflow-hidden">
      <div className="xs:px-6 px-8 sm:px-12 md:px-16 py-12 sm:py-16 flex flex-col items-center w-full max-w-3xl bg-white">
        <h1 className="text-4xl sm:text-5xl font-semibold text-center">
          Download Gertrude
        </h1>
        <p className="text-lg sm:text-xl text-slate-500 max-w-2xl mt-4 text-center">
          The Gertrude mac app is free to download, but requires a parent account to start
          protecting a computer. If you don’t have a parent account, you can start a 60
          day trial with no credit card by{` `}
          <Link href="https://gertrude.app/start">clicking here.</Link>
        </p>
        <FancyLink
          type="link"
          href="https://gertrude.nyc3.digitaloceanspaces.com/releases/Gertrude.dmg"
          Icon={DownloadIcon}
          className="mt-8 mb-12"
        >
          Download
        </FancyLink>
        <div className="w-full sm:bg-violet-50 p-0 sm:p-8 lg:p-12 rounded-3xl">
          <h2 className="text-xl font-medium text-center text-violet-800/40 mb-4">
            Supported operating systems:
          </h2>
          <div className="flex flex-col xs:flex-row flex-wrap justify-center gap-4">
            <SupportedOSCard os="Catalina" image={Catalina} />
            <SupportedOSCard os="Big Sur" image={BigSur} />
            <SupportedOSCard os="Monterey" image={Monterey} />
            <SupportedOSCard os="Ventura" image={Ventura} />
            <SupportedOSCard os="Sonoma" image={Sonoma} />
          </div>
        </div>
      </div>
      <div className="xs:flex flex-row xl:flex-col justify-between items-center p-12 xl:p-20 xl:w-96 hidden">
        <div className="w-28 md+:w-52 h-28 md+:h-52 flex justify-center items-center">
          <AppIcon className="!shadow-none scale-50 md+:scale-100 absolute" />
        </div>
        <ArrowDownIcon
          className="text-violet-800 opacity-10 relative md+:left-4 xl:left-0 xl:-top-4 -rotate-90 xl:rotate-0 shrink-0 scale-50 md:scale-100"
          size={80}
        />
        <div className="w-36 md+:w-64 xl:w-80 h-32 md+:h-52 flex justify-center items-end">
          <Computer
            labelStatus="hidden"
            children={undefined}
            className={`scale-[20%] md+:scale-[35%] xl:scale-[40%] relative -bottom-28 md+:-bottom-12`}
          />
        </div>
      </div>
    </div>
  </div>
);

export default DownloadPage;

const SupportedOSCard: React.FC<{ os: string; image: StaticImageData }> = ({
  os,
  image,
}) => (
  <div className="flex flex-col items-center xs:w-40 py-4 bg-violet-50 sm:bg-white/80 rounded-3xl">
    <Image src={image} alt={os} className="w-16 h-16" />
    <span className="text-slate-400 text-sm mt-2">macOS</span>
    <span className="text-xl font-semibold">{os}</span>
  </div>
);
