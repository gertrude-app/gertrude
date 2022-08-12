import React from 'react';
import cx from 'classnames';
import Logo from '../../Logo';
import SidebarOption from './SidebarOption';

interface Props {
  collapsed?: boolean;
  toggleCollapsed?: () => unknown;
  onLogout(): unknown;
  urlPath: string;
}

const SidebarNav: React.FC<Props> = ({
  collapsed = false,
  toggleCollapsed,
  onLogout,
  urlPath,
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
        >
          Dashboard
        </SidebarOption>
        <SidebarOption
          icon="users"
          collapsed={collapsed}
          to="/users"
          isSelected={urlPath.startsWith(`/users`)}
        >
          Users
        </SidebarOption>
        <SidebarOption
          icon="key"
          collapsed={collapsed}
          to="/keychains"
          isSelected={urlPath.startsWith(`/keychains`)}
        >
          Keychains
        </SidebarOption>
        <SidebarOption
          icon="user"
          collapsed={collapsed}
          to="/profile"
          isSelected={urlPath.startsWith(`/profile`)}
        >
          Profile
        </SidebarOption>
      </div>
      <div className={cx(`grow border-t-4 border-white border-opacity-10 pt-4`)}>
        <SidebarOption
          icon="life-ring"
          collapsed={collapsed}
          to="/support"
          isSelected={false}
        >
          Support
        </SidebarOption>
        <SidebarOption icon="cog" collapsed={collapsed} to="/settings" isSelected={false}>
          Settings
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
        <i
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
        Log out <i className="ml-1.5 fa fa-sign-out" />
      </button>
    </div>
  </div>
);

export default SidebarNav;
