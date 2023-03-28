import React from 'react';
import cx from 'classnames';
import { Button } from '@shared/components';
import { SelectMenu } from '@dash/components';

type Page = 'home' | 'health_check' | 'exempt_users';

interface Props {
  healthCheck: {
    appVersion: string;
    mostRecentAppVersion: string;
    filterVersion: string;
    mostRecentFilterVersion: string;
    screenRecordingPermission: boolean;
    keystrokeRecordingPermission: boolean;
    isAdministrator: boolean;
    filterToAppCommunicationVerified: boolean;
    notificationSetting: 'banners' | 'alert' | 'none';
    accountStatus: 'active' | 'inactive';
    keysLoaded: number;
  };
  filterStatus: 'on' | 'off' | 'suspended';
}

const Administrate: React.FC<Props> = ({ healthCheck, filterStatus }) => {
  const [page, setPage] = React.useState<Page>('home');
  const failingChecksCount = [
    healthCheck.appVersion === healthCheck.mostRecentAppVersion,
    healthCheck.filterVersion === healthCheck.mostRecentFilterVersion,
    healthCheck.screenRecordingPermission,
    healthCheck.keystrokeRecordingPermission,
    healthCheck.filterToAppCommunicationVerified,
    healthCheck.notificationSetting === 'alert',
    healthCheck.accountStatus === 'active',
    healthCheck.keysLoaded > 0,
  ].filter((item) => !item).length;

  let filterIndicatorColor = 'bg-green-500';
  let setFilterButtonColor: 'warning' | 'primary' | 'secondary' = 'warning';
  let setFilterButtonText = 'Stop';
  switch (filterStatus) {
    case 'off':
      filterIndicatorColor = 'bg-red-500';
      setFilterButtonColor = 'primary';
      setFilterButtonText = 'Start';
      break;
    case 'suspended':
      filterIndicatorColor = 'bg-yellow-500';
      setFilterButtonColor = 'secondary';
      setFilterButtonText = 'Resume';
      break;
  }

  return (
    <div className="flex h-full">
      <nav className="border-slate-200 dark:border-slate-800 border-r p-2 font-bold flex flex-col items-stretch space-y-1 bg-white dark:bg-slate-900">
        <SidebarButton
          page="home"
          currentPage={page}
          setCurrentPage={setPage}
          icon="home"
        />
        <SidebarButton
          page="health_check"
          currentPage={page}
          setCurrentPage={setPage}
          icon="heart-pulse"
        />
        <SidebarButton
          page="exempt_users"
          currentPage={page}
          setCurrentPage={setPage}
          icon="users"
        />
      </nav>
      <main className="flex-grow bg-white dark:bg-slate-900 rounded-br-xl p-4">
        <header className="flex space-x-4">
          <div className="bg-white dark:bg-slate-800/50 rounded-xl shadow border-slate-200 dark:border-slate-700 border-[0.5px] flex-grow">
            <div className="p-4 flex justify-between items-center">
              <div className="flex items-center space-x-2">
                <div className={`${filterIndicatorColor} w-3 h-3 rounded-full`} />
                <h3 className="text-slate-800 dark:text-slate-100 font-bold text-xl">
                  Filter is {filterStatus}
                </h3>
              </div>
              <Button
                type="button"
                onClick={() => {}}
                color={setFilterButtonColor}
                size="small"
              >
                {setFilterButtonText} filter
              </Button>
            </div>
            <div className="p-4 bg-slate-50 dark:bg-slate-900/50 rounded-b-xl flex space-x-4 items-center">
              <Button
                type="button"
                onClick={() => {}}
                color="tertiary"
                size="small"
                disabled={filterStatus !== 'on'}
              >
                Suspend filter
              </Button>
              <SelectMenu
                size="small"
                options={[
                  { value: '5', display: 'for 5 minutes' },
                  { value: '10', display: 'for 10 minutes' },
                  { value: '30', display: 'for 30 minutes' },
                  { value: '60', display: 'for 1 hour' },
                ]}
                selectedOption={''}
                setSelected={function (value: string): void {
                  throw new Error('Function not implemented.');
                }}
              />
            </div>
          </div>
          <div className="bg-white dark:bg-slate-800/50 rounded-xl shadow border-slate-200 dark:border-slate-700 border-[0.5px] p-4 flex-grow relative overflow-hidden">
            <div
              className={cx(
                'absolute top-1 right-1 w-10 h-10 bg-red-100 rounded-xl rounded-bl-3xl flex justify-center items-center',
                failingChecksCount === 0 && 'hidden',
              )}
            >
              <i className="fa-solid fa-exclamation text-red-500 text-xl" />
            </div>
            <h3 className="text-lg font-bold text-slate-700 dark:text-slate-100 relative">
              {failingChecksCount === 0
                ? `Everything looks good!`
                : `Some health checks are failing`}
            </h3>
            <p className="text-slate-500 dark:text-slate-400 mt-0.5">
              {failingChecksCount === 0
                ? `All health checks are passing`
                : `View health check to fix ${failingChecksCount} issues`}
            </p>
            <Button
              type="button"
              onClick={() => setPage('health_check')}
              color={failingChecksCount === 0 ? 'tertiary' : 'warning'}
              size="small"
              className="absolute right-4 bottom-4"
            >
              See health check
            </Button>
          </div>
        </header>
      </main>
    </div>
  );
};

export default Administrate;

interface SideBarButtonProps {
  page: Page;
  currentPage: Page;
  setCurrentPage: (page: Page) => void;
  icon: string;
}

const SidebarButton: React.FC<SideBarButtonProps> = ({
  page,
  currentPage,
  setCurrentPage,
  icon,
}) => {
  return (
    <button
      onClick={() => setCurrentPage(page)}
      className={cx(
        `transition duration-100 w-12 h-12 flex justify-center items-center rounded-lg`,
        page === currentPage
          ? `bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400`
          : `text-slate-500 hover:bg-slate-50 dark:hover:bg-slate-800/50 hover:text-slate-600 dark:hover:text-slate-400`,
      )}
    >
      <i className={`fa-solid fa-${icon} text-2xl`} />
    </button>
  );
};
