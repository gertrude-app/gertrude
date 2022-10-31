import Logo from '@shared/Logo';
import Chrome from 'components/Chrome';
import type { NextPage } from 'next';
import BigSur from '../public/macos-big-sur.png';
import Monterey from '../public/macos-monterey.png';
import Ventura from '../public/macos-ventura.png';

const Download: NextPage = () => (
  <Chrome>
    <section className="bg-gradient-to-b from-violet-500 to-fuchsia-500 flex-grow flex flex-col justify-center items-center p-6 py-10">
      <div className="bg-gray-50 shadow-xl rounded-3xl py-8 px-6 xs:px-10 sm:px-20 flex flex-col items-center mb-6">
        <Logo type="default" iconOnly size={60} className="mb-4 xs:mb-6" />
        <h1 className="text-3xl font-inter mb-4 xs:mb-6 text-center">
          Download Gertrude
        </h1>
        <p className="text-gray-500 mb-6 text-center">
          We currently support the following operating systems:
        </p>
        <div className="flex flex-col xs:flex-row space-y-2 xs:space-y-0 xs:space-x-6 self-stretch">
          <OperatingSystem name="Big Sur" img={BigSur.src} />
          <OperatingSystem name="Monterey" img={Monterey.src} />
          <OperatingSystem name="Ventura" img={Ventura.src} />
        </div>
      </div>
      <a
        href="https://gertrude.nyc3.digitaloceanspaces.com/releases/Gertrude.dmg"
        className="bg-gradient-to-b from-white via-white to-fuchsia-100 px-8 py-4 text-2xl rounded-xl shadow-xl shadow-fuchsia-600 font-medium hover:-translate-y-1 transition duration-100 hover:shadow-2xl active:translate-y-1 active:shadow-md active:scale-95 hover:shadow-fuchsia-700"
      >
        <span className="bg-gradient-to-br from-indigo-600 to-fuchsia-600 bg-clip-text text-transparent">
          <i className="fa-solid fa-download mr-2" /> Download
        </span>
      </a>
    </section>
  </Chrome>
);

export default Download;

interface OperatingSystemProps {
  name: string;
  img: string;
}

const OperatingSystem: React.FC<OperatingSystemProps> = ({ name, img }) => (
  <div className="flex flex-row xs:flex-col items-center p-3 rounded-xl shadow-lg bg-white flex-grow">
    <img src={img} width={70} height={70} alt="macOS operating system icon" />
    <div className="mt-1 flex flex-col items-start xs:items-center ml-2 xs:ml-0">
      <label className="text-sm text-gray-500 -mb-1">macOS</label>
      <h3 className="font-bold text-gray-700 text-lg">{name}</h3>
    </div>
  </div>
);
