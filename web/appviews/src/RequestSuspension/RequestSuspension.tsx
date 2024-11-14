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
import ErrorScreen from '../ErrorScreen';
import InactiveAccountScreen from '../components/InactiveAccountBlock';
import AccountPastDueBanner from '../components/AccountPastDueBanner';
import FullScreenSlider from '../components/FullScreenSlider';
import store, { STANDARD_DURATION_OPTIONS } from './requestsuspension-store';

type Props = PropsOf<AppState, ViewState, AppEvent, ViewAction>;

export const RequestSuspension: React.FC<Props> = ({
  dispatch,
  emit,
  comment,
  page,
  request,
  duration,
  adminAccountStatus,
  internetConnected,
  filterCommunicationConfirmed,
}) => {
  if (!internetConnected) {
    return (
      <ErrorScreen title="No Internet!">
        You must be connected to the internet in order to submit a filter suspension
        request. If you’re trying to connect to a public wifi network, consider
        temporarily using a hotspot.
      </ErrorScreen>
    );
  }
  if (filterCommunicationConfirmed === false) {
    return (
      <ErrorScreen
        title="Can't suspend filter!"
        button={{
          text: `Administrate`,
          action: () => emit({ case: `noFilterCommunicationAdministrateClicked` }),
          icon: `fa-cog`,
        }}
      >
        Sorry, we’re having trouble communicating with the internet filter, so we can’t
        suspend the filter right now. If a parent is nearby, they can likely fix the
        problem from the <b>Health Check screen.</b> If not,{` `}
        <b>restarting the computer</b> will fix the problem.
      </ErrorScreen>
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
      <ErrorScreen
        title="Filter suspension request failed:"
        children={request.error}
        button={{
          text: `Try Again`,
          icon: `fa-redo`,
          action: () => emit({ case: `requestFailedTryAgainClicked` }),
        }}
        className="h-full"
      />
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
    <FullScreenSlider
      pages={[
        <DurationPage
          emit={emit}
          adminAccountStatus={adminAccountStatus}
          dispatch={dispatch}
          duration={duration}
        />,
        <CommentPage
          emit={emit}
          comment={comment}
          dispatch={dispatch}
          duration={duration}
          isActive={page === `comment`}
        />,
      ]}
      index={page === `duration` ? 0 : 1}
    />
  );
};

const DurationPage: React.FC<
  Pick<Props, 'duration' | 'dispatch' | 'emit' | 'adminAccountStatus'>
> = ({ duration, dispatch, emit, adminAccountStatus }) => (
  <div className="flex flex-col bg-white dark:bg-slate-900 h-full relative">
    <div className="flex flex-col justify-start items-center flex-grow p-10 mb-20">
      <h3 className="font-bold mb-3 dark:text-slate-100">Choose a suspension duration</h3>
      <div className="grid grid-cols-3 gap-2">
        {STANDARD_DURATION_OPTIONS.map((seconds) => (
          <button
            key={seconds}
            className={cx(
              `text-left rounded-lg px-3 py-2 border-[0.5px] border-slate-200 dark:border-slate-700/50 bg-slate-50 dark:bg-slate-800/50 font-medium text-slate-700 dark:text-slate-100 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors duration-100 min-w-[180px]`,
              seconds === duration.seconds &&
                `!bg-violet-100 dark:!bg-violet-700/60 !border-violet-200 dark:!border-violet-600 !text-violet-700 dark:!text-violet-100 hover:!bg-violet-200 dark:hover:!bg-violet-700`,
            )}
            onClick={() => dispatch({ type: `standardDurationClicked`, seconds })}
          >
            {time.humanDuration(seconds)}
          </button>
        ))}
      </div>
      <div className="flex justify-center my-2.5">
        <span className="before:[content:'-_'] after:[content:'_-'] uppercase text-sm text-slate-400 dark:text-slate-500">
          or
        </span>
      </div>
      <button
        className="rounded-lg p-2 border-[0.5px] border-slate-200 dark:border-slate-700/50 bg-slate-50 dark:bg-slate-800/50 font-medium text-slate-700 dark:text-slate-100 text-center hover:bg-slate-100 dark:hover:bg-slate-800 w-[200px]"
        onClick={() => dispatch({ type: `chooseCustomDurationClicked` })}
      >
        Custom duration...
      </button>
      <div
        className={cx(
          `absolute left-0 top-0 bg-slate-200 dark:bg-slate-900 w-full h-full rounded-b-lg backdrop-blur-xl duration-300 transition-[opacity,display,background-color]`,
          duration.mode === `custom`
            ? `opacity-80 dark:opacity-90 block hover:bg-slate-300 dark:hover:bg-slate-800`
            : `opacity-0 hidden`,
        )}
        onClick={() => dispatch({ type: `closeCustomDurationDrawer` })}
      />
      <div
        className={cx(
          `absolute left-0 bottom-0 w-full bg-white dark:bg-slate-900 rotate-180 transition-shadow duration-300`,
          duration.mode === `custom` &&
            `shadow-md dark:shadow-lg shadow-slate-300/30 dark:shadow-black/30 rounded-b-xl`,
        )}
      >
        <div
          className={cx(
            `border-t border-slate-200 dark:border-slate-700/70 dark:bg-slate-800/30 flex flex-col justify-end rounded-b-xl rotate-180 relative overflow-hidden duration-300 transition-[height]`,
            duration.mode === `custom` ? `h-48 rounded-t-xl` : `h-20`,
          )}
        >
          <div
            className={cx(
              `absolute w-full left-0 flex justify-center transition-opacity duration-300 top-0`,
              duration.mode === `custom` ? `opacity-100` : `opacity-0`,
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
              className={cx(`max-w-sm relative top-8`)}
              unit="minutes"
            />
          </div>
          <button
            className={cx(
              `absolute top-2 w-6 h-6 bg-slate-100 dark:bg-slate-700 rounded-full flex justify-center items-center hover:scale-105 hover:bg-slate-200 dark:hover:bg-slate-600 duration-300 transision-[opacity,right] active:scale-95`,
              duration.mode === `custom` ? `opacity-100 right-2` : `opacity-0 -right-6`,
            )}
            onClick={() => dispatch({ type: `closeCustomDurationDrawer` })}
          >
            <i className="fa-solid fa-times text-slate-400 text-sm" />
          </button>
          <div
            className={cx(
              `p-4 flex flex-row-reverse justify-between items-center relative z-10`,
            )}
          >
            <Button
              type="button"
              onClick={() => dispatch({ type: `nextFromDurationPageClicked` })}
              color="secondary"
              disabled={!duration.seconds || (duration.seconds ?? 0) > 60 * 60 * 24 * 7}
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
        </div>
      </div>
    </div>
  </div>
);

const CommentPage: React.FC<
  Pick<Props, 'comment' | 'dispatch' | 'duration' | 'emit'> & { isActive: boolean }
> = ({ comment, dispatch, duration, emit, isActive }) => (
  <div className="flex flex-col bg-white dark:bg-slate-900 h-full">
    <div className="flex-grow flex flex-col justify-center items-center p-8">
      <h3 className="text-slate-900 text-lg font-bold mb-4 dark:text-slate-200">
        Add an optional comment
      </h3>
      <TextInput
        type="textarea"
        disabled={!isActive} // disable to prevent early tab focus issue
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
  </div>
);

export default containerize<AppState, AppEvent, ViewState, ViewAction>(
  store,
  RequestSuspension,
);
