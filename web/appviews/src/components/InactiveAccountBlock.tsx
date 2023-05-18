import React from 'react';
import cx from 'classnames';
import { Button } from '@shared/components';

interface Props {
  short?: boolean;
}

const InactiveAccountScreen: React.FC<Props> = ({ short }) => (
  <div
    className={cx(
      `h-full appview:h-screen flex flex-col justify-center items-center bg-white dark:bg-slate-900 rounded-b-xl`,
      short ? `p-4` : `p-8`,
    )}
  >
    <div
      className={cx(
        `border-2 border-red-200 dark:border-red-500/40 rounded-2xl h-full flex flex-col bg-red-50 dark:bg-red-500/20`,
        short ? `p-6` : `p-8`,
      )}
    >
      <div className="flex-grow flex flex-col space-y-4 text-slate-900 dark:text-slate-100">
        <h1 className="text-2xl font-medium">
          Your Gertrude account is <strong>no longer active.</strong>
        </h1>
        {!short && (
          <p>
            The internet filter will continue protecting this computer according to the
            rules set before the account went inactive, but no changes or suspensions can
            be made until the account is restored.
          </p>
        )}
        <p>
          To <strong>restore the account,</strong> login to the Gertrude web admin
          dashboard, resolve the payment issue, and click the <strong>Recheck</strong>
          {` `}
          button below.
        </p>
        {!short && (
          <p>
            If you no longer with to use Gertrude, click the <strong>Disconnect</strong>
            {` `}
            button below, then uninstall the app.
          </p>
        )}
        <p>
          Contact us at at{` `}
          <a
            href="mailto:support@gertrude.app"
            className="font-semibold text-slate-800 dark:text-slate-200 border-b-2 pb-1 border-red-50 dark:border-transparent hover:border-slate-600 dark:hover:border-slate-100 hover:pb-0.5 [transition:200ms]"
          >
            support@gertrude.app
          </a>
          {` `}
          to get help.
        </p>
      </div>
      <div className="flex items-center space-x-4 bg-white dark:bg-slate-900 p-4 rounded-xl self-stretch justify-between border border-red-200 dark:border-red-500/50">
        <Button type="button" onClick={() => {}} color="secondary">
          <i className="fa-solid fa-sync mr-3" />
          Recheck
        </Button>
        <Button type="button" onClick={() => {}} color="warning">
          <i className="fa-solid fa-plug mr-3" />
          Disconnect
        </Button>
      </div>
    </div>
  </div>
);

export default InactiveAccountScreen;
