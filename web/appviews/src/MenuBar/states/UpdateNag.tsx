import React from 'react';
import type { AppEvent } from '../menubar-store';
import { MenuBarSized } from '../MenuBar';

interface Props {
  emit(event: AppEvent): unknown;
}

const UpdateNag: React.FC<Props> = ({ emit }) => (
  <MenuBarSized className="flex flex-col justify-center items-center px-8">
    <p className="mb-3 font-inter text-black dark:text-white text-2xl">Required Update</p>
    <p className="text-black/80 dark:text-white/70 font-medium">
      Gertrude needs to update! If your parent is available, ask them to click update. It
      will only take a few seconds.
    </p>
    <div className="flex mt-8 gap-3">
      <button
        onClick={() => emit({ case: `updateNagUpdateClicked` })}
        className="flex items-center text-lg font-bold bg-violet-500/90 px-7 py-3 rounded-xl shadow-md transition duration-100 hover:bg-violet-600/90 hover:-translate-y-0.5 hover:shadow-lg active:translate-y-0 active:shadow"
      >
        <i className="fa fa-sync text-xl w-6 mr-2 text-white" />
        <span className="text-white">Update</span>
      </button>
      <button
        onClick={() => emit({ case: `updateNagDismissClicked` })}
        className="flex items-center text-lg font-bold bg-white/90 px-5 py-3 rounded-xl shadow-md transition duration-100 hover:bg-white/100 hover:-translate-y-0.5 hover:shadow-lg active:translate-y-0 active:shadow"
      >
        <i className="fa fa-stopwatch text-xl w-6 mr-2 text-gray-600/80" />
        <span className="text-gray-600 antialiased">Do it later...</span>
      </button>
    </div>
  </MenuBarSized>
);

export default UpdateNag;
