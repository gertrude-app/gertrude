import React from 'react';
import cx from 'classnames';
import type { Page } from '../Administrate';

interface Props {
  page: Page;
  setPage: (page: Page) => void;
}

const SidebarNav: React.FC<Props> = ({ page, setPage }) => (
  <nav className="border-slate-200 dark:border-slate-800 border-r p-2 font-bold flex flex-col items-stretch space-y-1 bg-white dark:bg-slate-900 rounded-bl-xl">
    <SidebarButton page="home" currentPage={page} setCurrentPage={setPage} icon="home" />
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
);

export default SidebarNav;

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
}) => (
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
