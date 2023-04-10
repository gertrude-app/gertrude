import React from 'react';
import { MenuBarSized } from '../MenuBar';

interface Props {
  error: string;
}

const ConnectFailed: React.FC<Props> = ({ error }) => {
  return (
    <MenuBarSized className="p-2 flex flex-col justify-center items-center">
      <div className="p-6 bg-red-500/20 dark:bg-red-500/20 rounded-xl">
        <h1 className="text-lg font-bold dark:text-white">
          Uh-oh, something went wrong:
        </h1>
        <p className="text-red-600 dark:text-red-200 font-medium">{error}</p>
        <div className="flex space-x-2 justify-between mt-4">
          <button className="px-6 py-1.5 rounded-lg bg-white/30 dark:bg-white/20 font-bold active:scale-95 transition duration-100 hover:bg-white/20 dark:hover:bg-white/30 dark:text-white">
            Get help
          </button>
          <button className="px-6 py-1.5 rounded-lg bg-white dark:bg-white/80 font-bold active:scale-95 transition duration-100 hover:bg-white/80 dark:hover:bg-white">
            Try again
          </button>
        </div>
      </div>
    </MenuBarSized>
  );
};

export default ConnectFailed;
