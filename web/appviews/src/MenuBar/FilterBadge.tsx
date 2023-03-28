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
      `text-white px-3 py-0.5 rounded-full text-[13px] font-medium uppercase dark:border`,
      onClick && `cursor-pointer`,
      {
        'bg-red-500 dark:bg-red-500/30 dark:border-red-500/70 dark:text-red-200':
          color === `red`,
        'bg-yellow-500 dark:bg-yellow-500/30 dark:border-yellow-500/70 dark:text-yellow-200':
          color === `orange`,
        'bg-green-500 dark:bg-green-500/30 dark:border-green-500/70 dark:text-green-300':
          color === `green`,
        'bg-gray-500/70 hover:bg-gray-600/70 antialiased text-gray-100 dark:bg-gray-800/60 hover:dark:bg-gray-900/80 dark:border-gray-500 dark:text-gray-300':
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
