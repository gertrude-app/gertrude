import React, { useState } from 'react';
import cx from 'classnames';
import { Button } from '@shared/components';

interface Props {
  short?: boolean;
  onRecheck(): unknown;
  onDisconnect(): unknown;
}

const InactiveAccountScreen: React.FC<Props> = ({ short, onRecheck, onDisconnect }) => {
  const [rechecking, setRechecking] = useState(false);
  const [disconnecting, setDisconnecting] = useState(false);
  return (
    <div
      className={cx(
        `min-h-screen flex flex-col justify-center items-center bg-white dark:bg-slate-900`,
        short ? `p-4` : `p-8`,
      )}
    >
      <div
        className={cx(
          `border border-red-100 dark:border-red-500/40 rounded-2xl h-full flex flex-col bg-red-50/50 dark:bg-red-500/20`,
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
              rules set before the account went inactive, but no changes or suspensions
              can be made until the account is restored.
            </p>
          )}
          <p>
            To <strong>restore the account,</strong> login to the Gertrude parent site and
            resolve the payment issue, then click the <strong>Recheck</strong>
            {` `}
            button below.
          </p>
          {!short && (
            <p>
              If you no longer wish to use Gertrude, click the <strong>Disconnect</strong>
              {` `}
              button below, then uninstall the app.
            </p>
          )}
          <p>
            Contact us at at{` `}
            <a
              href="https://gertrude.app/contact"
              className="font-semibold text-slate-800 dark:text-slate-200 border-b-2 pb-1 border-transparent dark:border-transparent hover:border-slate-600 dark:hover:border-slate-100 hover:pb-0.5 duration-200 transition-[padding-bottom,border-color]"
            >
              https://gertrude.app/contact
            </a>
            {` `}
            to get help.
          </p>
        </div>
        <div className="flex items-center mt-6 space-x-4 bg-white dark:bg-slate-900 p-4 rounded-xl self-stretch justify-between border border-red-100 dark:border-red-500/50">
          <Button
            type="button"
            onClick={() => {
              setRechecking(true);
              setTimeout(() => setRechecking(false), 3000);
              onRecheck();
            }}
            color="secondary"
            disabled={rechecking}
          >
            <i className={cx(`fa-solid fa-sync mr-3`, rechecking && `animate-spin`)} />
            {rechecking ? `Rechecking...` : `Recheck`}
          </Button>
          <Button
            type="button"
            onClick={() => {
              setDisconnecting(true);
              setTimeout(() => setDisconnecting(false), 6000);
              onDisconnect();
            }}
            color="warning"
            disabled={disconnecting}
          >
            <i
              className={cx(
                `fa-solid mr-3`,
                disconnecting ? `fa-sync animate-spin` : `fa-plug`,
              )}
            />
            {disconnecting ? `Disconnecting...` : `Disconnect`}
          </Button>
        </div>
      </div>
    </div>
  );
};

export default InactiveAccountScreen;
