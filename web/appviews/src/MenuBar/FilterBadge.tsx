import React from 'react';
import cx from 'classnames';

interface Props {
  color: 'red' | 'green' | 'orange' | 'grey';
  children: React.ReactNode;
  onClick?: () => unknown;
}

const FilterBadge: React.FC<Props> = ({ color, onClick, children }) => (
  <span
    onClick={onClick}
    className={cx(
      `text-white px-3 py-0.5 rounded-full text-[13px] font-medium uppercase dark:border transition`,
      onClick && `cursor-pointer`,
      {
        'bg-red-500 dark:bg-red-500/30 dark:border-red-500/70 dark:text-red-200':
          color === `red`,
        'bg-yellow-500 dark:bg-yellow-500/30 dark:border-yellow-500/70 dark:text-yellow-200':
          color === `orange`,
        'bg-green-500 dark:bg-green-500/30 dark:border-green-500/70 dark:text-green-300':
          color === `green`,
        'bg-slate-500/70 hover:bg-slate-600/70 antialiased text-slate-100 dark:bg-slate-800/60 hover:dark:bg-slate-900/80 transition duration-100 dark:border-slate-500 dark:text-slate-300':
          color === `grey`,
      },
    )}
  >
    {children}
  </span>
);

export default FilterBadge;

export const FilterStateBadge: React.FC<{ state: 'off' | 'on' | 'suspended' }> = ({
  state,
}) => (
  <FilterBadge color={state === `off` ? `red` : state === `on` ? `green` : `orange`}>
    {state}
  </FilterBadge>
);
