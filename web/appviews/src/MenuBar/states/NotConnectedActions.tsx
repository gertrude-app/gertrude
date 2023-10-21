import React from 'react';
import type { AppEvent } from '../menubar-store';
import { MenuBarSized } from '../MenuBar';

interface Props {
  emit(event: AppEvent): unknown;
  onBackClicked(): unknown;
  filterInstalled: boolean;
}

const NotConnectedActions: React.FC<Props> = ({
  emit,
  onBackClicked,
  filterInstalled,
}) => (
  <MenuBarSized className="flex flex-col justify-center items-center relative">
    <button
      onClick={onBackClicked}
      className="flex items-center text-md cursor-pointer absolute top-4 left-4 text-black/20 hover:text-black/40 dark:text-white/20 hover:dark:text-white/40 transition-colors"
    >
      <i className="fa-solid fa-chevron-left pr-2" />
      <span className="uppercase text-sm">back</span>
    </button>
    <div className="flex flex-col space-y-4 mt-4">
      {filterInstalled && (
        <Action
          label="Remove internet filter"
          onClick={() => emit({ case: `removeFilterClicked` })}
        />
      )}
      <Action
        label="Quit app for now"
        onClick={() => emit({ case: `quitForNowClicked` })}
      />
      <Action
        label="Quit app for uninstall"
        onClick={() => emit({ case: `quitForUninstallClicked` })}
      />
    </div>
  </MenuBarSized>
);

export default NotConnectedActions;

const Action: React.FC<{ label: string; onClick: () => unknown }> = ({
  label,
  onClick,
}) => (
  <button
    className="text-slate-600 w-56 py-2 shadow-md rounded-md font-bold bg-white/80 text-sm duration-150 transition-[background-color,transform,box-shadow] hover:bg-white/100 hover:-translate-y-[1px] hover:shadow-lg active:translate-y-0 active:shadow"
    onClick={onClick}
  >
    {label}
  </button>
);
