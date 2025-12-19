import { Logo } from '@shared/components';
import React from 'react';
import type { AppEvent } from '../menubar-store';
import { MenuBarSized } from '../MenuBar';

interface Props {
  emit(event: AppEvent): unknown;
  onActionsIconClicked(): unknown;
}

const NotConnected: React.FC<Props> = ({ emit, onActionsIconClicked }) => (
  <MenuBarSized className="flex flex-col justify-center items-center relative">
    <i
      onClick={onActionsIconClicked}
      className="fa-solid fa-gear text-md cursor-pointer absolute top-4 left-4 os-gte-14:m-[14px] text-black/10 hover:text-black/30 dark:text-white/10 hover:dark:text-white/30 transition-colors"
    />
    <p className="text-black/80 dark:text-white/70 font-medium">Welcome to</p>
    <Logo type="default" className="dark:[filter:brightness(600%)]" />
    <button
      onClick={() => emit({ case: `connectClicked` })}
      className="flex items-center text-lg font-bold bg-white/90 px-6 py-3 rounded-xl mt-8 shadow-md transition-[background-color,transform,box-shadow] duration-100 hover:bg-white/100 hover:-translate-y-0.5 hover:shadow-lg active:translate-y-0 active:shadow"
    >
      <i className="fa fa-laptop text-xl w-6 mr-3 text-indigo-600" />
      <span className="bg-gradient-to-br from-indigo-600 to-fuchsia-600 bg-clip-text text-transparent [-webkit-background-clip:text;]">
        Connect to child
      </span>
    </button>
  </MenuBarSized>
);

export default NotConnected;
