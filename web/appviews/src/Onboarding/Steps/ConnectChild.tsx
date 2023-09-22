import React from 'react';
import cx from 'classnames';
import { Button } from '@shared/components';
import type { AppEvent, RequestState, ViewAction } from '../onboarding-store';

interface Props {
  emit(event: AppEvent): unknown;
  dispatch(action: ViewAction): unknown;
  connectionCode: string;
  request: RequestState<string, string>;
}

const ConnectChild: React.FC<Props> = ({ emit, dispatch, connectionCode, request }) => (
  <div className="h-full flex flex-col justify-center items-center relative">
    <div
      className={cx(
        `absolute transition-[opacity,transform] duration-500 flex flex-col items-center`,
        request.state === `idle` || request.state === `ongoing`
          ? `opacity-100`
          : `opacity-0 translate-y-12 pointer-events-none`,
      )}
    >
      <h1 className="text-3xl font-bold">Connect a child</h1>
      <p className="text-lg text-slate-500 mt-4">
        Enter the 6-digit connection code from the Gertrude parent's site:
      </p>
      <div className="flex mt-8 gap-4">
        <input
          type="text"
          onChange={() => alert(`TODO`)}
          value={connectionCode}
          className="shadow-lg shadow-slate-300/50 rounded-2xl text-3xl px-6 py-4 text-slate-600 font-bold font-mono w-64 tracking-[8px] border-2 border-white focus:border-violet-400 focus:ring-0 transition-[border-color,transform,box-shadow] duration-300 focus:shadow-xl focus:shadow-slate-300/50 focus:-translate-y-0.5 placeholder:text-slate-200"
          placeholder="******"
        />
        <button
          onClick={() => dispatch({ type: `updateConnectionCode`, code: connectionCode })}
          className="bg-gradient-to-r from-violet-500 to-fuchsia-500 px-6 text-xl flex justify-center items-center gap-3 font-medium text-white rounded-2xl shadow-xl shadow-violet-500/40 cursor-pointer hover:scale-[102%] active:scale-[98%] hover:shadow-2xl hover:shadow-violet-500/50 active:shadow-lg active:shadow-violet-500/30 transition-[transform,box-shadow] duration-300 outline-none focus:ring-0 w-44"
        >
          <div
            className={cx(
              `flex gap-3 items-center transition-[opacity,transform] duration-300 absolute`,
              request.state === `idle` ? `opacity-100` : `opacity-0 scale-50`,
            )}
          >
            <span>Connect</span>
            <i className="fa-solid fa-arrow-right" />
          </div>
          <div
            className={cx(
              `flex gap-3 items-center transition-[opacity,transform] duration-300 absolute`,
              request.state === `ongoing` ? `opacity-100` : `opacity-0 translate-y-4`,
            )}
          >
            <i className="fa-solid fa-spinner animate-spin" />
          </div>
        </button>
      </div>
    </div>
    <div
      className={cx(
        `absolute transition-[opacity,transform] duration-500 flex justify-center items-center flex-col bg-white p-12 rounded-3xl shadow-lg shadow-slate-300/30`,
        request.state === `succeeded`
          ? `opacity-100`
          : `opacity-0 translate-y-12 pointer-events-none`,
      )}
    >
      <h1 className="text-3xl font-bold">Success!</h1>
      <p className="mt-2 mb-6 text-lg text-slate-500">
        You've connected this computer to the child{` `}
        <span className="font-medium text-slate-600">
          {request.state === `succeeded` && request.payload}
        </span>
        .
      </p>
      <Button
        type="button"
        onClick={() => emit({ case: `primaryBtnClicked` })}
        color="primary"
        size="large"
      >
        Next
        <i className="fa-solid fa-arrow-right ml-2" />
      </Button>
    </div>
    <div
      className={cx(
        `absolute transition-[opacity,transform] duration-500 flex flex-col items-center border-2 p-16 rounded-3xl border-slate-200/50 border-dashed`,
        request.state === `failed`
          ? `opacity-100`
          : `opacity-0 translate-y-12 pointer-events-none`,
      )}
    >
      <h1 className="text-3xl font-bold">Uh-oh, something went wrong</h1>
      <p className="mt-2 mb-6 text-lg text-slate-500">Failed to connect child</p>
      <div className="flex flex-col justify-center w-80 gap-4">
        <Button
          type="button"
          onClick={() => emit({ case: `primaryBtnClicked` })}
          color="primary"
          size="large"
        >
          Try again
        </Button>
        <Button
          type="button"
          onClick={() => emit({ case: `secondaryBtnClicked` })}
          color="secondary"
          size="large"
        >
          Get help
        </Button>
      </div>
    </div>
  </div>
);

export default ConnectChild;
