import cx from 'classnames';
import React, { useState } from 'react';
import type { Screen } from '../administrate-store';

interface Props {
  screen: Screen;
  setScreen(screen: Screen): unknown;
}

const SidebarNav: React.FC<Props> = ({ screen, setScreen }) => {
  const [timesHiddenClicked, setTimesHiddenClicked] = useState(0);
  return (
    <nav
      className={cx(
        `border-slate-200 dark:border-slate-800 border-r p-2 font-bold flex flex-col items-stretch space-y-1 bg-white dark:bg-slate-900 fixed h-full z-20 top-0`,
      )}
    >
      <SidebarButton
        isActive={screen === `healthCheck`}
        onClick={() => setScreen(`healthCheck`)}
        icon="heart-pulse"
      />
      <SidebarButton
        isActive={screen === `actions`}
        onClick={() => setScreen(`actions`)}
        icon="arrow-pointer"
      />
      <SidebarButton
        isActive={screen === `exemptUsers`}
        onClick={() => setScreen(`exemptUsers`)}
        icon="users"
      />
      <SidebarButton
        isActive={screen === `advanced`}
        onClick={() => {
          if (timesHiddenClicked < 10) {
            setTimesHiddenClicked(timesHiddenClicked + 1);
          } else {
            setScreen(`advanced`);
          }
        }}
        icon="flask"
        className={timesHiddenClicked < 10 ? `cursor-default opacity-0` : ``}
      />
    </nav>
  );
};

export default SidebarNav;

interface SideBarButtonProps {
  isActive: boolean;
  onClick(): unknown;
  icon: string;
  className?: string;
}

const SidebarButton: React.FC<SideBarButtonProps> = ({
  onClick,
  isActive,
  className,
  icon,
}) => (
  <button
    onClick={onClick}
    className={cx(
      `transition-colors duration-100 w-12 h-12 flex justify-center items-center rounded-lg`,
      isActive
        ? `bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400`
        : `text-slate-500 hover:bg-slate-50 dark:hover:bg-slate-800/50 hover:text-slate-600 dark:hover:text-slate-400`,
      className,
    )}
  >
    <i className={`fa-solid fa-${icon} text-2xl`} />
  </button>
);
