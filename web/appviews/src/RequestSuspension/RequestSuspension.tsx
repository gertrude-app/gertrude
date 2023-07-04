import React from 'react';
import cx from 'classnames';
import { inflect } from '@shared/string';
import { Button, Loading, TextInput } from '@shared/components';
import { Transition } from '@headlessui/react';
import type {
  AppState,
  ViewState,
  AppEvent,
  ViewAction,
} from './requestsuspension-store';
import type { PropsOf } from '../lib/store';
import { containerize } from '../lib/store';
import ErrorBlock from '../ErrorBlock';
import InactiveAccountScreen from '../components/InactiveAccountBlock';
import AccountPastDueBanner from '../components/AccountPastDueBanner';
import store from './requestsuspension-store';

type Props = PropsOf<AppState, ViewState, AppEvent, ViewAction>;

export const RequestSuspension: React.FC<Props> = ({
  overlay,
  dispatch,
  customDurationString,
  emit,
  comment,
  durationInSeconds,
  request,
  adminAccountStatus,
  internetConnected,
}) => {
  if (!internetConnected) {
    return (
      <div className="h-full appview:h-screen flex justify-center bg-white dark:bg-slate-900 items-center px-12">
        <ErrorBlock
          title="No Internet!"
          message="You must be connected to the internet in order to submit a filter suspension request. If you’re trying to connect to a public wifi network, consider temporarily using a hotspot."
        />
      </div>
    );
  }
  if (request.case === `ongoing`) {
    return (
      <div className="h-full appview:h-screen flex justify-center items-center flex-col space-y-4 bg-white dark:bg-slate-900 rounded-b-xl">
        <Loading />
        <h3 className="text-slate-500 font-medium text-lg dark:text-slate-400">
          Submitting...
        </h3>
      </div>
    );
  } else if (request.case === `succeeded`) {
    return (
      <div className="h-full appview:h-screen flex justify-center items-center p-8 bg-white dark:bg-slate-900 rounded-b-xl">
        <div className="flex justify-center items-center flex-col border border-slate-200 dark:border-slate-800 bg-slate-50/30 dark:bg-slate-800/30 rounded-2xl w-full h-full">
          <div className="flex flex-row items-center space-x-3 mb-8">
            <div className="bg-green-500 rounded-full w-6 h-6 flex justify-center items-center">
              <i className="fa-solid fa-check text-white dark:text-slate-900" />
            </div>
            <h3 className="text-lg text-slate-600 dark:text-slate-300 font-medium">
              Filter suspension request submitted
            </h3>
          </div>
          <Button
            type="button"
            color="secondary"
            onClick={() => emit({ case: `closeWindow` })}
          >
            <i className="mr-2 fa-solid fa-times" />
            Close window
          </Button>
        </div>
      </div>
    );
  } else if (request.case === `failed`) {
    return (
      <div className="h-full appview:h-screen flex justify-center items-center p-8 bg-white dark:bg-slate-900 rounded-b-xl">
        <ErrorBlock
          title="Filter suspension request failed:"
          message={request.error}
          button={{
            text: `Try Again`,
            icon: `fa-redo`,
            action: () => emit({ case: `requestFailedTryAgainClicked` }),
          }}
          className="h-full"
        />
      </div>
    );
  }

  if (adminAccountStatus === `inactive`) {
    return (
      <InactiveAccountScreen
        short
        onRecheck={() => emit({ case: `inactiveAccountRecheckClicked` })}
        onDisconnect={() => emit({ case: `inactiveAccountDisconnectAppClicked` })}
      />
    );
  }

  return (
    <div className="h-full appview:h-screen flex items-stretch flex-col bg-white dark:bg-slate-900 rounded-b-xl relative">
      {adminAccountStatus === `needsAttention` && <AccountPastDueBanner small />}
      <Transition
        show={overlay !== undefined}
        enter="transition-opacity duration-75"
        enterFrom="opacity-0"
        enterTo="opacity-100"
        leave="transition-opacity duration-150"
        leaveFrom="opacity-100"
        leaveTo="opacity-0"
      >
        <div
          className={cx(
            `absolute flex justify-center items-center w-full h-full top-0 left-0 bg-black/60 z-40 rounded-b-xl`,
          )}
          onClick={() => dispatch({ type: `overlayBackgroundClicked` })}
        >
          <div
            className={cx(
              `h-[330px] w-96 bg-white dark:bg-slate-800 rounded-xl shadow-xl relative overflow-hidden`,
            )}
            onClick={(event) => event.stopPropagation()}
          >
            <div
              className={cx(
                `absolute w-full flex flex-col items-stretch top-0 p-4 [transition:200ms]`,
                overlay === `main` ? `left-0 opacity-100` : `-left-96 opacity-0`,
              )}
            >
              <h3 className="font-bold mb-3 dark:text-slate-100">Suspension duration</h3>
              <div className="grid grid-cols-2 gap-2">
                {[3, 5, 10, 20, 30, 60, 90, 120].map((minutes) => (
                  <button
                    key={minutes}
                    className="text-left rounded-lg px-3 py-2 bg-slate-50 dark:bg-slate-700 font-medium text-slate-700 dark:text-slate-100 hover:bg-slate-100 dark:hover:bg-slate-600 transition duration-100"
                    onClick={() => dispatch({ type: `standardDurationClicked`, minutes })}
                  >
                    {minutes > 59 ? minutes / 60 : minutes}
                    {` `}
                    {minutes > 59 ? (minutes === 60 ? `hour` : `hours`) : `minutes`}
                  </button>
                ))}
              </div>
              <div className="flex justify-center my-2.5">
                <span className="before:[content:'-_'] after:[content:'_-'] uppercase text-sm text-slate-400">
                  or
                </span>
              </div>
              <button
                className="rounded-lg p-2 bg-slate-50 dark:bg-slate-700 font-medium text-slate-700 dark:text-slate-100 text-center hover:bg-slate-100 dark:hover:bg-slate-600"
                onClick={() => dispatch({ type: `customDurationClicked` })}
              >
                Custom duration...
              </button>
            </div>
            <div
              className={cx(
                `absolute w-full h-full top-0 [transition:200ms] flex flex-col justify-between`,
                overlay === `customDuration` ? `left-0 opacity-100` : `left-96 opacity-0`,
              )}
            >
              <div className="p-4">
                <h3 className="font-bold mb-3 dark:text-slate-100">
                  Choose a custom duration
                </h3>
                <TextInput
                  type="positiveInteger"
                  value={customDurationString}
                  setValue={(value) => dispatch({ type: `customDurationUpdated`, value })}
                  unit="minutes"
                />
              </div>
              <div className="flex justify-between items-center bg-slate-50 dark:bg-slate-900/50 p-4 rounded-b-xl">
                <Button
                  type="button"
                  onClick={() => dispatch({ type: `backFromCustomDurationClicked` })}
                  color="tertiary"
                  size="medium"
                >
                  <i className="fa-solid fa-arrow-left mr-2" />
                  Back
                </Button>
                <Button
                  type="button"
                  onClick={() => dispatch({ type: `chooseCustomDurationClicked` })}
                  color="secondary"
                  size="medium"
                  disabled={!customDurationValid(customDurationString)}
                >
                  Choose
                  <i className="fa-solid fa-check ml-2" />
                </Button>
              </div>
            </div>
          </div>
        </div>
      </Transition>
      <div
        className={cx(
          `p-8 bg-slate-50 dark:bg-slate-900 flex-grow flex justify-center flex-col items-center`,
          adminAccountStatus === `needsAttention` && `py-6`,
        )}
      >
        <h2 className="text-lg font-semibold text-center dark:text-slate-100">
          Request temporary filter suspension
        </h2>
        <TextInput
          type="textarea"
          value={comment}
          setValue={(value) => dispatch({ type: `commentUpdated`, value })}
          rows={adminAccountStatus === `needsAttention` ? 3 : 5}
          label="Reason:"
          noResize
          placeholder="Super compelling reason"
        />
      </div>
      <div className="flex justify-between items-center p-4 dark:bg-black/10 rounded-b-xl border-t border-slate-200 dark:border-slate-800">
        <Button
          type="button"
          onClick={() => dispatch({ type: `durationButtonClicked` })}
          color="tertiary"
          size="medium"
        >
          <i className="fa-regular fa-clock mr-2" />
          {chooseDurationButtonText(customDurationString, durationInSeconds)}
        </Button>
        <Button
          type="button"
          onClick={() => {
            const duration = chosenDurationInSeconds(
              customDurationString,
              durationInSeconds,
            );
            if (duration !== null) {
              emit({ case: `requestSubmitted`, durationInSeconds: duration, comment });
            }
          }}
          color="secondary"
          size="medium"
          disabled={
            overlay !== undefined ||
            chosenDurationInSeconds(customDurationString, durationInSeconds) === null
          }
        >
          Submit
          <i className="fa-solid fa-arrow-right ml-2" />
        </Button>
      </div>
    </div>
  );
};

function chosenDurationInSeconds(
  customDurationString: string,
  durationInSeconds?: number,
): number | null {
  if (customDurationValid(customDurationString)) {
    const minutes = Number(customDurationString);
    return minutes * 60;
  } else if (durationInSeconds !== undefined) {
    return durationInSeconds;
  } else {
    return null;
  }
}

function chooseDurationButtonText(
  customDurationString: string,
  durationInSeconds?: number,
): string {
  if (customDurationValid(customDurationString)) {
    const minutes = Number(customDurationString);
    return `${minutes} ${inflect(`minute`, minutes)}`;
  } else if (durationInSeconds !== undefined) {
    const minutes = Math.round(durationInSeconds / 60);
    if (minutes < 60) {
      return `${minutes} ${inflect(`minute`, minutes)}`;
    }
    const hours = Math.floor(minutes / 60);
    const left = minutes % 60;
    if (left === 0) {
      return `${hours} ${inflect(`hour`, hours)}`;
    }
    return `${hours} ${inflect(`hour`, hours)} ${left} ${inflect(`minute`, left)}`;
  } else {
    return `Choose duration...`;
  }
}

export default containerize<AppState, AppEvent, ViewState, ViewAction>(
  store,
  RequestSuspension,
);

function customDurationValid(input: string): boolean {
  return /^[1-9][0-9]*$/.test(input);
}
