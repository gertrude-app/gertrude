'use client';

import React from 'react';
import cx from 'classnames';
import { Switch } from '@headlessui/react';

interface Props {
  enabled: boolean;
  setEnabled: (enabled: boolean) => unknown;
  small?: boolean;
  testId?: string;
}

const Toggle: React.FC<Props> = ({ enabled, setEnabled, small, testId }) => (
  <Switch
    checked={enabled}
    onChange={setEnabled}
    className={cx(
      enabled ? `bg-violet-800 dark:bg-violet-600` : `bg-slate-200 dark:bg-slate-800`,
      small ? `h-5 w-9` : `h-6 w-11`,
      `relative inline-flex flex-shrink-0 border-2 border-transparent rounded-full cursor-pointer transition-colors ease-in-out duration-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-violet-500 dark:ring-offset-slate-900`,
    )}
    {...(testId ? { 'data-test': testId } : {})}
  >
    <span
      aria-hidden="true"
      className={cx(
        enabled ? (small ? `translate-x-4` : `translate-x-5`) : `translate-x-0`,
        small ? `h-4 w-4` : `h-5 w-5`,
        `pointer-events-none inline-block rounded-full bg-white dark:bg-slate-200 shadow transform ring-0 transition-transform ease-in-out duration-200`,
      )}
    />
  </Switch>
);

export default Toggle;
