import React from 'react';
import cx from 'classnames';
import { time } from '@shared/datetime';
import { Button, Loading, TextInput } from '@shared/components';
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
import store, { STANDARD_DURATION_OPTIONS } from './requestsuspension-store';

type Props = PropsOf<AppState, ViewState, AppEvent, ViewAction>;

export const RequestSuspension: React.FC<Props> = ({
  dispatch,
  emit,
  comment,
  page,
  duration,
  request,
  adminAccountStatus,
  internetConnected,
}) => {
  if (!internetConnected) {
    return (
      <div className="min-h-screen flex justify-center bg-white dark:bg-slate-900 items-center px-12">
        <ErrorBlock
          title="No Internet!"
          message="You must be connected to the internet in order to submit a filter suspension request. If you’re trying to connect to a public wifi network, consider temporarily using a hotspot."
        />
      </div>
    );
  }
  if (request.case === `ongoing`) {
    return (
      <div className="min-h-screen flex justify-center items-center flex-col space-y-4 bg-white dark:bg-slate-900">
        <Loading />
        <h3 className="text-slate-500 font-medium text-lg dark:text-slate-400">
          Submitting...
        </h3>
      </div>
    );
  } else if (request.case === `succeeded`) {
    return (
      <div className="min-h-screen flex justify-center items-center p-8 bg-white dark:bg-slate-900">
        <div className="flex justify-center items-center flex-col border border-slate-200 dark:border-slate-800 bg-slate-50/30 dark:bg-slate-800/30 rounded-2xl self-stretch w-full">
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
      <div className="min-h-screen flex justify-center items-center p-8 bg-white dark:bg-slate-900">
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
    <div className="min-h-screen flex relative overflow-hidden">
      <div
        className={cx(
          `p-4 z-10 w-screen flex flex-row-reverse justify-between items-center absolute bottom-0 left-0`,
          page === `comment` && `hidden`,
        )}
      >
        <Button
          type="button"
          onClick={() => dispatch({ type: `nextFromDurationPageClicked` })}
          color="secondary"
          disabled={!duration.seconds}
        >
          Next
          <i className="ml-3 fa-solid fa-chevron-right" />
        </Button>
        {adminAccountStatus === `needsAttention` ? (
          <AccountPastDueBanner small withoutBorder />
        ) : (
          <Button
            type="button"
            onClick={() =>
              emit({
                case: `grantSuspensionClicked`,
                durationInSeconds: duration.seconds ?? 0,
              })
            }
            color="tertiary"
            disabled={!duration.seconds}
          >
            <i className="mr-3 fa-solid fa-lock" />
            Grant suspension
          </Button>
        )}
      </div>
      <RequestSuspensionPage
        pageType="duration"
        currentlyViewedPage={page}
        className="flex flex-col bg-white dark:bg-slate-900"
      >
        <div className="flex flex-col justify-center items-center flex-grow pb-20">
          <h3 className="font-bold mb-3 dark:text-slate-100">
            Choose a suspension duration
          </h3>
          <div className="grid grid-cols-3 gap-2">
            {STANDARD_DURATION_OPTIONS.map((seconds) => {
              const minutes = seconds / 60;
              return (
                <button
                  key={minutes}
                  className={cx(
                    `text-left rounded-lg px-3 py-2 border-[0.5px] border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 font-medium text-slate-700 dark:text-slate-100 hover:bg-slate-100 dark:hover:bg-slate-700 transition duration-100 min-w-[180px]`,
                    seconds === duration.seconds &&
                      `!bg-violet-100 dark:!bg-violet-700/60 !border-violet-200 dark:!border-violet-600 !text-violet-700 dark:!text-violet-100 hover:!bg-violet-200 dark:hover:!bg-violet-700`,
                  )}
                  onClick={() => dispatch({ type: `standardDurationClicked`, seconds })}
                >
                  {time.humanDuration(seconds)}
                </button>
              );
            })}
          </div>
          <div className="flex justify-center my-2.5">
            <span className="before:[content:'-_'] after:[content:'_-'] uppercase text-sm text-slate-400 dark:text-slate-500">
              or
            </span>
          </div>
          <button
            className="rounded-lg p-2 border-[0.5px] border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 font-medium text-slate-700 dark:text-slate-100 text-center hover:bg-slate-100 dark:hover:bg-slate-700 w-[200px]"
            onClick={() => dispatch({ type: `chooseCustomDurationClicked` })}
          >
            Custom duration...
          </button>
          <div
            className={cx(
              `absolute left-0 top-0 bg-slate-100 dark:bg-slate-900 w-full h-full rounded-b-lg backdrop-blur-xl [transition:300ms]`,
              duration.mode === `custom`
                ? `opacity-80 block hover:bg-slate-200 dark:hover:bg-slate-800`
                : `opacity-0 hidden`,
            )}
            onClick={() => dispatch({ type: `closeCustomDurationDrawer` })}
          />
          <div
            className={cx(
              `absolute left-0 bottom-0 w-full bg-white dark:bg-slate-900 rotate-180 transition duration-30 rounded-t-lg`,
              duration.mode === `custom` &&
                `shadow-md dark:shadow-lg shadow-slate-300/30 dark:shadow-black/30 rounded-b-xl`,
            )}
          >
            <div
              className={cx(
                `border-t border-slate-200 dark:border-slate-700/70 dark:bg-slate-800/30 p-4 flex flex-col justify-end rounded-b-lg rotate-180 relative overflow-hidden`,
                `[transition:300ms]`,
                duration.mode === `custom` ? `h-48 rounded-t-xl` : `h-20`,
              )}
            >
              <div
                className={cx(
                  `absolute w-full left-0 flex justify-center [transition:300ms]`,
                  duration.mode === `custom` ? `top-0` : `top-16`,
                )}
              >
                <TextInput
                  key={duration.mode} // number type local value override
                  type="positiveInteger"
                  value={String(duration.seconds ? duration.seconds / 60 : 90)}
                  setValue={(value) =>
                    dispatch({
                      type: `customDurationUpdated`,
                      seconds: Number(value) * 60,
                    })
                  }
                  className={cx(
                    `max-w-sm [transition:300ms] relative top-8`,
                    duration.mode === `custom` ? `opacity-100` : `opacity-0`,
                  )}
                  unit="minutes"
                />
              </div>
              <button
                className={cx(
                  `absolute top-2 w-6 h-6 bg-slate-100 dark:bg-slate-700 rounded-full flex justify-center items-center hover:scale-105 hover:bg-slate-200 dark:hover:bg-slate-600 [transition:300ms] active:scale-95`,
                  duration.mode === `custom`
                    ? `opacity-100 right-2`
                    : `opacity-0 -right-6`,
                )}
                onClick={() => dispatch({ type: `closeCustomDurationDrawer` })}
              >
                <i className="fa-solid fa-times text-slate-400 text-sm" />
              </button>
            </div>
          </div>
        </div>
      </RequestSuspensionPage>
      <RequestSuspensionPage
        pageType={`comment`}
        currentlyViewedPage={page}
        className="flex flex-col bg-white dark:bg-slate-900"
      >
        <div className="flex-grow flex flex-col justify-center items-center p-8">
          <h3 className="text-slate-900 text-lg font-bold mb-4 dark:text-slate-200">
            Add an optional comment
          </h3>
          <TextInput
            type="textarea"
            value={comment}
            setValue={(value) => dispatch({ type: `commentUpdated`, value })}
            placeholder="Super compelling reason"
            noResize
            className="max-w-[550px] justify-center"
            rows={3}
          />
        </div>
        <div className="h-20 flex justify-between p-4 border-t border-slate-200 dark:border-slate-700 items-center">
          <Button
            type="button"
            onClick={() => dispatch({ type: `backFromCommentPageClicked` })}
            color="tertiary"
            disabled={!duration.seconds}
          >
            <i className="mr-3 fa-solid fa-chevron-left" />
            Back
          </Button>
          <span className="font-medium text-slate-400 dark:text-slate-600">
            {time.humanDuration(duration.seconds || 0)}
          </span>
          <Button
            type="button"
            onClick={() =>
              emit({
                case: `requestSubmitted`,
                durationInSeconds: duration.seconds || 0,
                comment,
              })
            }
            color="secondary"
            disabled={!duration.seconds}
          >
            Request suspension
            <i className="ml-3 fa-solid fa-chevron-right" />
          </Button>
        </div>
      </RequestSuspensionPage>
    </div>
  );
};

interface RequestSuspensionPageProps {
  pageType: 'duration' | 'comment';
  currentlyViewedPage: 'duration' | 'comment';
  children: React.ReactNode;
  className?: string;
}

const RequestSuspensionPage: React.FC<RequestSuspensionPageProps> = ({
  pageType,
  currentlyViewedPage,
  children,
  className,
}) => (
  <div
    className={cx(
      `h-screen w-screen absolute top-0 [transition:300ms] duration-200`,
      pageType === `duration` &&
        currentlyViewedPage === `comment` &&
        `--left-screen opacity-0`,
      pageType === currentlyViewedPage && `left-0 opacity-100`,
      pageType === `comment` &&
        currentlyViewedPage === `duration` &&
        `left-screen opacity-0`,
      className,
    )}
  >
    {children}
  </div>
);

export default containerize<AppState, AppEvent, ViewState, ViewAction>(
  store,
  RequestSuspension,
);
