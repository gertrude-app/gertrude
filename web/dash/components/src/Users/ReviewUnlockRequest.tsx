import React from 'react';
import cx from 'classnames';
import { relativeTime } from '@dash/datetime';
import type { UnlockRequest } from '@dash/types';
import UserInputText from '../UserInputText';

type Props = {
  detailsExpanded: boolean;
  setDetailsExpanded(expanded: boolean): unknown;
} & UnlockRequest;

const ReviewUnlockRequest: React.FC<Props> = ({
  userName,
  requestComment,
  url,
  domain,
  ipAddress,
  createdAt,
  appName,
  appCategories,
  appBundleId,
  detailsExpanded,
  setDetailsExpanded,
}) => (
  <>
    <div className="flex flex-col sm:flex-row justify-between items-center sm:items-start mb-4 px-3 sm:pt-2">
      <div className="flex flex-col items-center sm:items-start sm:min-w-[105px] mr-4">
        <h1 className="text-xl font-bold whitespace-nowrap pr-3">{userName}</h1>
        <h3 className="text-slate-500">{relativeTime(createdAt)}</h3>
      </div>
      {requestComment && (
        <div className="mt-3 sm:mt-0">
          <UserInputText className="text-center sm:text-left">
            &ldquo;{requestComment}&rdquo;
          </UserInputText>
        </div>
      )}
    </div>
    <div className="bg-slate-50 p-3 rounded-xl *overflow-scroll">
      <a
        className="text-blue-700 hover:underline focus:outline-none cursor-pointer break-all"
        href={url || (domain && `https://${domain}`) || ipAddress}
        target="_blank"
        rel="noopener noreferrer"
      >
        <i className="fa-solid fa-arrow-up-right-from-square mr-2" />
        {url || domain || ipAddress}
      </a>
    </div>
    <div className="bg-white border border-slate-200 rounded-xl mb-1 flex flex-col mt-4 relative">
      <button
        className="hover:text-slate-600 text-slate-400 transition-[color] duration-100 absolute right-2.5 top-0 text-lg p-2 bg-transparent"
        onClick={() => setDetailsExpanded(!detailsExpanded)}
      >
        <i
          className={cx(
            `fa-solid fa-chevron-down transition-transform duration-100`,
            detailsExpanded && `-rotate-180`,
          )}
        />
      </button>
      {appName ? (
        <AppDetail expanded={detailsExpanded} label="App" data={appName} />
      ) : (
        <AppDetail expanded={detailsExpanded} label="App Bundle ID" data={appBundleId} />
      )}
      {detailsExpanded && (
        <>
          <AppDetail
            expanded={detailsExpanded}
            label="App category"
            data={appCategories.join(`, `)}
          />
          {appName && (
            <AppDetail expanded={detailsExpanded} label="Bundle ID" data={appBundleId} />
          )}
          <AppDetail expanded={detailsExpanded} label="URL" data={url} />
          <AppDetail expanded={detailsExpanded} label="Domain" data={domain} />
          <AppDetail expanded={detailsExpanded} label="IP Address" data={ipAddress} />
        </>
      )}
    </div>
  </>
);

export default ReviewUnlockRequest;

interface AppDetailProps {
  expanded: boolean;
  label: string;
  data?: string;
}

const AppDetail: React.FC<AppDetailProps> = ({ label, data, expanded }) => {
  if (!data) {
    return null;
  }
  return (
    <div className="flex items-start p-3 px-5 text-sm sm:text-md odd:bg-slate-50 last:rounded-b-xl">
      <h3
        className={cx(
          `text-slate-600 antialiased pr-3 font-medium`,
          expanded && `min-w-[108px]`,
        )}
      >
        {label}:
      </h3>
      <h2 className="text-slate-900 font-bold break-all">{data}</h2>
    </div>
  );
};
