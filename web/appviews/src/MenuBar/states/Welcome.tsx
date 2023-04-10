import React from 'react';
import { Logo } from '@shared/components';
import type { AppEvent } from '../menubar-store';
import { MenuBarSized } from '../MenuBar';
import Laptop from '../../Icons/Laptop';

interface Props {
  emit: (event: AppEvent) => unknown;
}

const Welcome: React.FC<Props> = ({ emit }) => {
  return (
    <MenuBarSized className="flex flex-col justify-center items-center">
      <p className="text-black/80 dark:text-white/70 font-medium">Welcome to</p>
      <Logo type="default" className="dark:[filter:brightness(600%)]" />
      <button
        onClick={() => emit({ case: `connectClicked` })}
        className="flex items-center text-lg font-bold bg-white/90 px-6 py-3 rounded-xl mt-8 shadow-md transition duration-100 hover:bg-white/100 hover:-translate-y-0.5 hover:shadow-lg active:translate-y-0 active:shadow"
      >
        <Laptop className="w-6 mr-3 text-indigo-600" />
        <span className="bg-gradient-to-br from-indigo-600 to-fuchsia-600 bg-clip-text text-transparent [-webkit-background-clip:text;]">
          Connect a device
        </span>
      </button>
    </MenuBarSized>
  );
};

export default Welcome;
