import React from 'react';
import cx from 'classnames';
import type { Screen } from '../administrate-store';

interface Props {
  screen: Screen;
  setScreen(screen: Screen): unknown;
}

const SidebarNav: React.FC<Props> = ({ screen, setScreen }) => (
  <nav className="border-slate-200 dark:border-slate-800 border-r p-2 font-bold flex flex-col items-stretch space-y-1 bg-white dark:bg-slate-900 rounded-bl-xl">
    <SidebarButton
      destinationScreen="home"
      currentScreen={screen}
      setScreen={setScreen}
      icon="home"
    />
    <SidebarButton
      destinationScreen="healthCheck"
      currentScreen={screen}
      setScreen={setScreen}
      icon="heart-pulse"
    />
    <SidebarButton
      destinationScreen="exemptUsers"
      currentScreen={screen}
      setScreen={setScreen}
      icon="users"
    />
  </nav>
);

export default SidebarNav;

interface SideBarButtonProps {
  destinationScreen: Screen;
  currentScreen: Screen;
  setScreen(screen: Screen): unknown;
  icon: string;
}

const SidebarButton: React.FC<SideBarButtonProps> = ({
  destinationScreen,
  currentScreen,
  setScreen,
  icon,
}) => (
  <button
    onClick={() => setScreen(destinationScreen)}
    className={cx(
      `transition duration-100 w-12 h-12 flex justify-center items-center rounded-lg`,
      destinationScreen === currentScreen
        ? `bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400`
        : `text-slate-500 hover:bg-slate-50 dark:hover:bg-slate-800/50 hover:text-slate-600 dark:hover:text-slate-400`,
    )}
  >
    <i className={`fa-solid fa-${icon} text-2xl`} />
  </button>
);
