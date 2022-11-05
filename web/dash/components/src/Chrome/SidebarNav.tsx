import React from 'react';
import cx from 'classnames';
import { Logo } from '@shared/components';
import SidebarOption from './SidebarOption';

interface Props {
  collapsed?: boolean;
  toggleCollapsed?: () => unknown;
  onLogout(): unknown;
  onInternalLinkClick(): unknown;
  urlPath: string;
}

const SidebarNav: React.FC<Props> = ({
  collapsed = false,
  toggleCollapsed,
  onLogout,
  urlPath,
  onInternalLinkClick,
}) => (
  <div className="flex flex-col justify-between h-full">
    <nav className={cx(`flex flex-col`, collapsed ? `py-4` : `px-4`)}>
      <Logo
        type="on-dark"
        className={cx(
          `mb-4 sm:mb-6 scale-[0.8] sm:scale-100`,
          collapsed ? `mt-3 ml-[1.2em]` : `mt-8 -ml-3 sm:ml-4`,
        )}
        iconOnly={collapsed}
      />
      <div className={cx(`pb-4`)}>
        <SidebarOption
          icon="home"
          collapsed={collapsed}
          to="/"
          isSelected={urlPath === `/`}
          onClick={onInternalLinkClick}
        >
          Dashboard
        </SidebarOption>
        <SidebarOption
          icon="users"
          collapsed={collapsed}
          to="/users"
          isSelected={urlPath.startsWith(`/users`)}
          onClick={onInternalLinkClick}
        >
          Users
        </SidebarOption>
        <SidebarOption
          icon="key"
          collapsed={collapsed}
          to="/keychains"
          onClick={onInternalLinkClick}
          isSelected={urlPath.startsWith(`/keychains`)}
        >
          Keychains
        </SidebarOption>
        <SidebarOption
          icon="user"
          collapsed={collapsed}
          to="/profile"
          onClick={onInternalLinkClick}
          isSelected={urlPath.startsWith(`/profile`)}
        >
          Profile
        </SidebarOption>
      </div>
      <div className={cx(`grow border-t-4 border-white border-opacity-10 pt-4`)}>
        <SidebarOption
          icon="book"
          collapsed={collapsed}
          to="https://docs.gertrude.app"
          isSelected={false}
        >
          Docs
        </SidebarOption>
        <SidebarOption
          icon="life-ring"
          collapsed={collapsed}
          to="https://gertrude.app/contact"
          isSelected={false}
        >
          Support
        </SidebarOption>
      </div>
    </nav>
    <div
      className={cx(`flex h-16 pb-px`, {
        'justify-center': collapsed,
        'justify-between': !collapsed && toggleCollapsed !== undefined,
        'justify-end': !collapsed && toggleCollapsed === undefined,
      })}
    >
      <button
        type="button"
        className={cx(
          `px-4 ml-px items-center justify-start hidden md:flex`,
          `bg-black bg-opacity-0 hover:bg-opacity-10 cursor-pointer transition duration-100`,
          `focus:outline-none focus:ring-2 focus:ring-inset focus:ring-violet-500/50 rounded-md`,
        )}
        onClick={toggleCollapsed}
      >
        <span className="sr-only">
          {collapsed ? `Maximize sidebar` : `Minimize sidebar`}
        </span>
        <i
          aria-hidden="true"
          className={cx(
            `fas text-2xl text-white text-opacity-60`,
            collapsed ? `fa-chevron-right` : `fa-chevron-left mr-3`,
          )}
        />
      </button>
      <button
        type="button"
        className={cx(
          collapsed ? `hidden` : `flex`,
          `justify-end items-center px-4 mr-px`,
          `text-white text-opacity-50 text-right hover:text-opacity-60 whitespace-nowrap`,
          `transition duration-100 cursor-pointer`,
          `focus:outline-none focus:ring-2 focus:ring-inset focus:ring-violet-500/50 rounded-md`,
        )}
        onClick={onLogout}
      >
        Log out <i aria-hidden="true" className="ml-1.5 fa fa-sign-out" />
      </button>
    </div>
  </div>
);

export default SidebarNav;
