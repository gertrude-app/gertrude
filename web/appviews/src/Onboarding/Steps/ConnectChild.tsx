import React, { useContext, useRef, useEffect } from 'react';
import cx from 'classnames';
import type { RequestState } from '../onboarding-store';
import * as Onboarding from '../UtilityComponents';
import OnboardingContext from '../OnboardingContext';

interface Props {
  connectionCode: string;
  request: RequestState<string, string>;
}

const ConnectChild: React.FC<Props> = ({ connectionCode, request }) => {
  const inputRef = useRef<HTMLInputElement>(null);
  const { currentStep, emit, dispatch, os } = useContext(OnboardingContext);
  const codeValid = connectionCode.match(/^\d{6}$/) !== null;

  useEffect(() => {
    // catalina and big sur both showed wonky layout issues, caused by the focus
    if (currentStep === `connectChild` && os === `venturaOrLater`) {
      inputRef.current?.focus({ preventScroll: true });
    }
  }, [currentStep, os]);

  useEffect(() => {
    const listener: (event: KeyboardEvent) => void = (event: KeyboardEvent) => {
      if (event.key === `Enter` && codeValid) {
        emit({ case: `connectChildSubmitted`, code: Number(connectionCode) });
      }
    };
    window.addEventListener(`keydown`, listener);
    return () => window.removeEventListener(`keydown`, listener);
  });

  return (
    <Onboarding.Centered className="relative">
      <div
        className={cx(
          `absolute transition-[opacity,transform] duration-500 flex flex-col items-center`,
          request.case === `idle` || request.case === `ongoing`
            ? `opacity-100`
            : `opacity-0 translate-y-12 pointer-events-none`,
        )}
      >
        <h1 className="text-3xl font-bold">Connect a child</h1>
        <p className="text-lg text-slate-500 mt-4">
          Enter the 6-digit connection code from the Gertrude parent’s site:
        </p>
        <div className="flex mt-8 space-x-4">
          <input
            ref={inputRef}
            disabled={currentStep !== `connectChild`}
            type="text"
            onChange={(event) =>
              dispatch({ type: `connectionCodeUpdated`, code: event.target.value })
            }
            value={connectionCode}
            className="shadow-lg shadow-slate-300/50 rounded-2xl text-3xl px-6 py-4 text-slate-600 font-bold font-mono w-64 tracking-[8px] border-2 border-white focus:border-violet-400 focus:ring-0 transition-[border-color,transform,box-shadow] duration-300 focus:shadow-xl focus:shadow-slate-300/50 focus:-translate-y-0.5 placeholder:text-slate-200"
            placeholder="******"
          />
          <button
            onClick={() =>
              codeValid &&
              emit({ case: `connectChildSubmitted`, code: Number(connectionCode) })
            }
            className={cx(
              `bg-gradient-to-r from-violet-500 to-fuchsia-500 px-6 text-xl flex justify-center items-center font-medium text-white rounded-2xl shadow-xl shadow-violet-500/40 transition-[transform,box-shadow,opacity] duration-300 outline-none focus:ring-0 w-44`,
              codeValid
                ? `cursor-pointer hover:scale-[102%] active:scale-[98%] hover:shadow-2xl hover:shadow-violet-500/50 active:shadow-lg active:shadow-violet-500/30`
                : `cursor-not-allowed opacity-80`,
            )}
          >
            <div
              className={cx(
                `flex space-x-3 items-center transition-[opacity,transform] duration-300 absolute`,
                request.case === `idle` ? `opacity-100` : `opacity-0 scale-50`,
              )}
            >
              <span>Connect</span>
              <i className="fa-solid fa-arrow-right" />
            </div>
            <div
              className={cx(
                `flex items-center transition-[opacity,transform] duration-300 absolute`,
                request.case === `ongoing` ? `opacity-100` : `opacity-0 translate-y-4`,
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
          request.case === `succeeded`
            ? `opacity-100`
            : `opacity-0 translate-y-12 pointer-events-none`,
        )}
      >
        <h1 className="text-3xl font-bold">Success!</h1>
        <p className="mt-2 mb-6 text-lg text-slate-500">
          You’ve connected this computer to the child{` `}
          <span className="font-medium text-slate-600">
            {request.case === `succeeded` && request.payload}
          </span>
          .
        </p>
        <Onboarding.PrimaryButton icon="fa-solid fa-arrow-right">
          Next
        </Onboarding.PrimaryButton>
      </div>
      <div
        className={cx(
          `absolute transition-[opacity,transform] duration-500 flex flex-col items-center border-2 p-16 rounded-3xl border-slate-200/50 border-dashed`,
          request.case === `failed`
            ? `opacity-100`
            : `opacity-0 translate-y-12 pointer-events-none`,
        )}
      >
        <h1 className="text-3xl font-bold">Uh-oh, something went wrong</h1>
        <p className="mt-2 mb-6 text-lg text-slate-500">
          {request.case === `failed` ? request.error : `Failed to connect child`}
        </p>
        <Onboarding.ButtonGroup
          primary={{ text: `Try again`, icon: false }}
          secondary={{ text: `Get help` }}
          className="w-80"
        />
      </div>
    </Onboarding.Centered>
  );
};

export default ConnectChild;
