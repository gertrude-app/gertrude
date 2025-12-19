import React from 'react';
import type { AppEvent } from '../menubar-store';
import { MenuBarSized } from '../MenuBar';

interface Props {
  emit(event: AppEvent): unknown;
}

const UpdateRequired: React.FC<Props> = ({ emit }) => (
  <MenuBarSized className="flex flex-col justify-center items-center px-8">
    <p className="mb-3 font-inter text-black dark:text-white text-2xl">
      <i className="fa fa-triangle-exclamation text-3xl w-6 mr-4 translate-y-0.5" />
      Update Required
    </p>
    <p className="text-black/80 dark:text-white/70 font-medium mt-2">
      No actions can be performed until Gertrude is updated. Normal protection rules are
      still in effect. Please have your parent complete the update by clicking below.
    </p>
    <button
      onClick={() => emit({ case: `updateRequiredUpdateClicked` })}
      className="flex items-center text-lg font-bold bg-violet-500/90 dark:bg-violet-700/90 px-7 py-3 mt-6 rounded-xl shadow-md transition-[box-shadow,transform,background-color] duration-100 hover:bg-violet-600/90 dark:hover:bg-violet-800/90 hover:-translate-y-0.5 hover:shadow-lg active:translate-y-0 active:shadow"
    >
      <i className="fa fa-sync text-xl w-6 mr-2 text-white" />
      <span className="text-white">Update Now</span>
    </button>
  </MenuBarSized>
);

export default UpdateRequired;
