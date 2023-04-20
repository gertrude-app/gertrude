import React from 'react';
import cx from 'classnames';
import { Button, TextInput, Toggle } from '@shared/components';
import type { AppState, ViewState, AppEvent, ViewAction } from './blockedrequests-store';
import type { PropsOf } from '../lib/store';
import { containerize } from '../lib/store';
import store from './blockedrequests-store';
import BlockedRequest from './BlockedRequest';

type Props = PropsOf<AppState, ViewState, AppEvent, ViewAction>;

export const BlockedRequests: React.FC<Props> = ({
  requests,
  filterText,
  tcpOnly,
  emit,
  dispatch,
  unlockRequestExplanation,
  selectedRequests,
  unlockRequest,
}) => {
  const filteredRequests = requests
    // TODO(jared): text filtering needs to be re-implmented more carefully
    .filter((req) => req.searchableText.toLowerCase().includes(filterText.toLowerCase()))
    .filter((req) => (tcpOnly ? req.protocol === `tcp` : true));
  return (
    <div className="bg-white dark:bg-slate-900 h-full flex flex-col rounded-b-xl">
      <header className="flex justify-between items-center p-4 border-b border-slate-200 dark:border-slate-800 dark:bg-slate-900">
        <div className="flex items-center">
          <input
            className="bg-slate-50 dark:bg-slate-800/50 dark:focus:bg-slate-800 rounded-xl px-4 py-2 w-80 transition duration-100 focus:bg-slate-50 focus:shadow-md outline-none border-[0.5px] dark:border-slate-700 placeholder:text-slate-400 dark:text-white dark:placeholder:text-slate-500"
            placeholder="Filter..."
            value={filterText}
            onChange={(e) => emit({ case: `updateFilterText`, text: e.target.value })}
          />
          <button
            className={cx(
              `border border-slate-200 dark:border-slate-700 w-7 h-7 rounded-full mx-3 hover:bg-slate-50 dark:hover:bg-slate-800 transition duration-100 flex justify-center items-center`,
              filterText
                ? `opacity-100 translate-y-0 cursor-pointer`
                : `opacity-0 translate-y-1 cursor-default`,
            )}
            onClick={() => emit({ case: `updateFilterText`, text: `` })}
          >
            <i className="fa-solid fa-times text-slate-500 text-sm" />
          </button>
        </div>
        <div className="flex items-center space-x-6 grow">
          <div className="flex items-center space-x-2">
            <Toggle
              enabled={tcpOnly}
              setEnabled={() => emit({ case: `toggleTcpOnly` })}
              small
            />
            <span className="text-slate-700 dark:text-slate-300 font-medium">
              TCP only
            </span>
          </div>
        </div>
        <Button color="tertiary" size="small" type="button" onClick={() => {}}>
          <i className="fa-solid fa-ban mr-2 text-red-400" />
          Clear requests
        </Button>
      </header>
      <div className="flex flex-col p-4 flex-grow overflow-y-scroll">
        {requests.length === 0 && <span>...waiting for requests</span>}
        {requests.length > 0 && filteredRequests.length === 0 && (
          <span>no matching requests</span>
        )}
        {filteredRequests.length > 0 &&
          filteredRequests.map((req) => (
            <BlockedRequest
              key={req.id}
              time={req.time}
              protocol={req.protocol}
              target={req.target}
              app={req.app}
              selected={selectedRequests.includes(req.id)}
              onSelectToggle={() =>
                dispatch({ type: `toggleRequestSelected`, id: req.id })
              }
            />
          ))}
      </div>
      <BottomPanel
        emit={emit}
        dispatch={dispatch}
        unlockRequestExplanation={unlockRequestExplanation}
        selectedRequests={selectedRequests}
        unlockRequest={unlockRequest}
      />
    </div>
  );
};

type PanelProps = Omit<Props, 'requests' | 'filterText' | 'tcpOnly' | 'windowOpen'>;

const BottomPanel: React.FC<PanelProps> = ({
  unlockRequestExplanation,
  dispatch,
  selectedRequests,
  unlockRequest,
  emit,
}) => {
  if (selectedRequests.length === 0 && unlockRequest.case === `idle`) {
    return null;
  }
  if (unlockRequest.case === `loading`) {
    return (
      <BottomPanelWrap>
        spinner here... (maybe extract component from menubar?)
      </BottomPanelWrap>
    );
  }
  if (unlockRequest.case === `succeeded`) {
    return (
      <BottomPanelWrap>
        Unlock request sent successfully! (i think a "close window" button might be nice
        here)
      </BottomPanelWrap>
    );
  }
  if (unlockRequest.case === `failed`) {
    return (
      <BottomPanelWrap>
        Failed to send unlock request:{` `}
        <span className="text-red-500 px-3">{unlockRequest.error}</span>
        <button
          className="border border-black px-3 py-1 rounded-md"
          onClick={() => dispatch({ type: `requestFailedTryAgainClicked` })}
        >
          try again
        </button>
      </BottomPanelWrap>
    );
  }
  return (
    <BottomPanelWrap className="justify-between">
      <TextInput
        type="textarea"
        value={unlockRequestExplanation}
        setValue={(value) => dispatch({ type: `explanationUpdated`, text: value })}
        rows={3}
        className="w-96"
        placeholder="Explanation..."
        noResize
      />
      <div className="flex flex-col justify-end items-end">
        <span className="text-slate-600 dark:text-slate-400 font-medium mb-3">
          {selectedRequests.length} addresses selected
        </span>
        <Button
          color="secondary"
          type="button"
          onClick={() => emit({ case: `unlockRequestSubmitted`, ids: selectedRequests })}
        >
          Send unlock request
          <i className="fa-solid fa-arrow-right ml-2" />
        </Button>
      </div>
    </BottomPanelWrap>
  );
};

const BottomPanelWrap: React.FC<{ className?: string; children: React.ReactNode }> = ({
  className,
  children,
}) => (
  <div className="border-b border-slate-200 dark:border-slate-800 shadow-xl shadow-black/5 dark:shadow-black/50 rotate-180">
    <div className={cx(`rotate-180 p-4 flex`, className)}>{children}</div>
  </div>
);

export default containerize<AppState, AppEvent, ViewState, ViewAction>(
  store,
  BlockedRequests,
);
