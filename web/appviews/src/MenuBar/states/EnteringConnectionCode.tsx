import React from 'react';
import cx from 'classnames';
import type { AppEvent, ViewAction } from '../menubar-store';
import { MenuBarSized } from '../MenuBar';

interface Props {
  emit(event: AppEvent): unknown;
  dispatch(action: ViewAction): unknown;
  connectionCode: string;
}

const EnteringConnectionCode: React.FC<Props> = ({ emit, connectionCode, dispatch }) => {
  const codeValid = connectionCode.match(/^\d{6}$/) !== null;
  function submit(): void {
    if (!codeValid) return;
    emit({ case: `connectSubmit`, code: Number(connectionCode) });
  }
  return (
    <MenuBarSized className="p-2">
      <form
        onSubmit={(e) => {
          e.preventDefault();
          submit();
        }}
        className="flex flex-col items-stretch justify-end h-full"
      >
        <div className="flex-grow flex flex-col justify-center items-center p-6">
          <h3 className="text-xl font-bold text-center dark:text-white">
            Enter connection code
          </h3>
          <h4 className="text-black/50 font-medium dark:text-white/60">
            from Gertrude dashboard
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
            type="button"
            // nb: using `disabled` and type=submit not working in webview
            onClick={submit}
            className={cx(
              `bg-gradient-to-br px-4 rounded-r-xl rounded-l font-medium text-white shadow transition duration-100 active:scale-95`,
              `from-indigo-500 to-fuchsia-500`,
              codeValid
                ? `hover:from-indigo-600 hover:to-fuchsia-600`
                : `cursor-not-allowed opacity-60`,
            )}
          >
            Submit
          </button>
        </div>
      </form>
    </MenuBarSized>
  );
};

export default EnteringConnectionCode;
