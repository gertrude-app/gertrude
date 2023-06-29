import React from 'react';
import type { AppEvent } from '../menubar-store';
import { MenuBarSized } from '../MenuBar';

interface Props {
  emit(event: AppEvent): unknown;
  userName: string;
}

const ConnectSucceeded: React.FC<Props> = ({ emit, userName }) => (
  <MenuBarSized className="flex flex-col justify-center items-center">
    <p className="text-black/80 dark:text-white/70 font-medium">
      Success! Connected to user:
    </p>
    <p className="mt-2 font-inter text-black dark:text-white text-xl">{userName}</p>
    <button
      onClick={() => emit({ case: `welcomeAdminClicked` })}
      className="flex items-center text-lg font-bold bg-white/90 px-6 py-3 rounded-xl mt-8 shadow-md transition duration-100 hover:bg-white/100 hover:-translate-y-0.5 hover:shadow-lg active:translate-y-0 active:shadow"
    >
      <span className="bg-gradient-to-br from-indigo-600 to-fuchsia-600 bg-clip-text text-transparent [-webkit-background-clip:text;]">
        Continue
      </span>
      <i className="fa fa-arrow-right text-xl w-6 ml-2 text-fuchsia-800" />
    </button>
  </MenuBarSized>
);

export default ConnectSucceeded;
