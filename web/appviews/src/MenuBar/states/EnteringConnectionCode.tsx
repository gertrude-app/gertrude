import React from 'react';
import { MenuBarSized } from '../MenuBar';
import { AppEvent, ViewAction } from '../menubar-store';

interface Props {
  emit: (event: AppEvent) => unknown;
  dispatch: (action: ViewAction) => unknown;
  connectionCode: string;
}

const EnteringConnectionCode: React.FC<Props> = ({ emit, connectionCode, dispatch }) => {
  return (
    <MenuBarSized className="p-2">
      <form
        onSubmit={(e) => {
          e.preventDefault();
          emit({ case: `connectSubmit`, code: Number(connectionCode) });
        }}
        className="flex flex-col items-stretch justify-end h-full"
      >
        <div className="flex-grow flex flex-col justify-center items-center p-6">
          <h3 className="text-xl font-bold text-center dark:text-white">
            Enter connection code
          </h3>
          <h4 className="text-black/50 font-medium dark:text-white/60">
            From Gertrude dashboard
          </h4>
        </div>
        <div className="flex justify-center rounded-xl space-x-1 bg-white/20 p-4">
          <input
            type="text"
            value={connectionCode}
            autoFocus
            onChange={(e) =>
              dispatch({ type: `connectionCodeUpdated`, code: e.target.value })
            }
            className="rounded-l-xl rounded-r border-none h-12 shadow focus:ring-indigo-500 focus:ring-2 transition duration-100"
          />
          <button
            type="submit"
            disabled={connectionCode.match(/^\d{6}$/) === null}
            className="bg-gradient-to-br from-indigo-500 to-fuchsia-500 hover:from-indigo-600 hover:to-fuchsia-600 px-4 rounded-r-xl rounded-l font-medium text-white shadow transition duration-100 active:scale-95"
          >
            {connectionCode.match(/^\d{6}$/) === null
              ? `invalid state, disable`
              : `Submit`}
          </button>
        </div>
      </form>
    </MenuBarSized>
  );
};

export default EnteringConnectionCode;
