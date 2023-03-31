import React from 'react';
import cx from 'classnames';
import { Button } from '@shared/components';
import FilterStatusBlock from './FilterStatusBlock';
import HealthCheckPreviewBlock from './HealthCheckPreviewBlock';
import SidebarNav from './SidebarNav';
import AppVersionBlock from './AppVersionBlock';
import UserBlock from './UserBlock';

export type Page = 'home' | 'health_check' | 'exempt_users';

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
  userName: string;
  screenshotMonitoringEnabled: boolean;
  keystrokeMonitoringEnabled: boolean;
}

const Administrate: React.FC<Props> = ({
  healthCheck,
  filterStatus,
  userName,
  screenshotMonitoringEnabled,
  keystrokeMonitoringEnabled,
}) => {
  const [page, setPage] = React.useState<Page>(`home`);
  const [debuggerOpen, setDebuggerOpen] = React.useState(false);
  const [debugging, setDebugging] = React.useState(false);

  const failingChecksCount = [
    healthCheck.appVersion === healthCheck.mostRecentAppVersion,
    healthCheck.filterVersion === healthCheck.mostRecentFilterVersion,
    healthCheck.screenRecordingPermission,
    healthCheck.keystrokeRecordingPermission,
    healthCheck.filterToAppCommunicationVerified,
    healthCheck.notificationSetting === `alert`,
    healthCheck.accountStatus === `active`,
    healthCheck.keysLoaded > 0,
  ].filter((item) => !item).length;

  return (
    <div className="flex h-full">
      <SidebarNav page={page} setPage={setPage} />
      <main className="flex-grow bg-white dark:bg-slate-900 rounded-br-xl flex flex-col justify-between p-4">
        <div className="flex flex-col space-y-4">
          <div className="flex space-x-4">
            <FilterStatusBlock filterStatus={filterStatus} />
            <HealthCheckPreviewBlock
              failingChecksCount={failingChecksCount}
              setPage={setPage}
            />
          </div>
          <AppVersionBlock appVersion={healthCheck.appVersion} />
          <UserBlock
            keystrokeMonitoringEnabled={keystrokeMonitoringEnabled}
            screenshotMonitoringEnabled={screenshotMonitoringEnabled}
            userName={userName}
          />
        </div>
        <footer className="mt-4 flex justify-between items-end">
          <div
            className={cx(
              `rounded-xl border-slate-200 dark:border-slate-800 border flex items-center justify-start overflow-hidden [transition:200ms]`,
              debuggerOpen ? `w-[200px]` : `w-[42px]`,
            )}
          >
            <button
              className="rounded-xl text-xl w-10 h-10 text-slate-400 dark:text-slate-600 hover:bg-slate-50 dark:hover:bg-slate-800 hover:text-slate-500 transition duration-100 shrink-0 relative flex justify-center items-center"
              onClick={() => setDebuggerOpen(!debuggerOpen)}
            >
              <i
                className={cx(
                  `fa-solid fa-circle text-xs transition duration-100 absolute animate-ping text-red-500`,
                  debugging ? `block` : `hidden`,
                )}
              />
              <i
                className={cx(
                  `fa-solid transition duration-100 relative`,
                  debugging ? `fa-circle text-[10px] text-red-500` : `fa-bug-slash`,
                )}
              />
            </button>
            <button
              className={cx(
                `mx-1.5 bg-slate-50 dark:bg-slate-900 text-slate-500 dark:text-slate-400 font-medium border-[0.5px] border-slate-200 dark:border-slate-600 hover:border-slate-300 hover:bg-white hover:text-slate-600 dark:hover:bg-slate-800 transition duration-200 rounded-lg px-2 py-0.5 active:scale-95 whitespace-nowrap`,
                debuggerOpen ? `opacity-100` : `opacity-0`,
              )}
              onClick={() => setDebugging(!debugging)}
            >
              {debugging ? `Stop debugging` : `Send debug data`}
            </button>
          </div>
          <Button type="button" onClick={() => {}} color="warning">
            Quit app
          </Button>
        </footer>
      </main>
    </div>
  );
};

export default Administrate;
