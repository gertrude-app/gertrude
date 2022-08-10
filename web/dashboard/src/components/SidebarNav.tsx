import React from 'react';
import Logo from '@shared/Logo';
import SidebarOption from './SidebarOption';

interface Props {
  expanded: boolean;
  setExpanded(expanded: boolean): void;
  open: boolean;
  setOpen(open: boolean): void;
}

const SidebarNav: React.FC<Props> = ({ expanded, setExpanded, open, setOpen }) => (
  <nav
    className={`h-screen fixed bg-gray-900 bg-gradient-to-br from-transparent to-violet-900/40 -ml-80 z-40 ${
      open ? (expanded ? `left-80` : `left-20`) : `left-0`
    } lg:-ml-0 flex flex-col justify-between items-start overflow-hidden [transition:200ms] ${
      expanded ? `w-72` : `w-20`
    }`}
  >
    <div
      className="absolute lg:hidden right-0 top-0 p-4 cursor-pointer text-white text-opacity-50 hover:text-opacity-60"
      onClick={() => setOpen(false)}
    >
      <i className="fa fa-times text-2xl transition duration-100" />
    </div>
    <div className={`${expanded ? `p-4` : `py-4`}`}>
      <Logo
        type="on-dark"
        className={`m-2 mb-10 mt-8 ${expanded ? `ml-4` : `ml-[1.2em]`}`}
        iconOnly={!expanded}
      />
      <a
        className={`text-white text-opacity-50 text-right absolute bottom-0 left-44 -ml-1 py-5 hover:text-opacity-60 transition duration-100 w-32 justify-center items-center cursor-pointer ${
          expanded ? `flex` : `hidden`
        }`}
        href="https://friendslibrary.com"
      >
        Log out <i className="ml-1.5 fa fa-sign-out" />
      </a>
      <div className="mt-5 pb-4">
        <SidebarOption icon="home" expanded={expanded} to="/">
          Dashboard
        </SidebarOption>
        <SidebarOption icon="users" expanded={expanded} to="/users">
          Users
        </SidebarOption>
        <SidebarOption icon="key" expanded={expanded} to="/keychains">
          Keychains
        </SidebarOption>
        <SidebarOption icon="user" expanded={expanded} to="/profile">
          Profile
        </SidebarOption>
      </div>
      <div className="border-t-4 border-white border-opacity-10 pt-4 -ml-4 pl-4">
        <SidebarOption icon="life-ring" expanded={expanded} to="/support">
          Support
        </SidebarOption>
        <SidebarOption icon="cog" expanded={expanded} to="/settings">
          Settings
        </SidebarOption>
      </div>
    </div>
    <div
      className={`items-center justify-start px-6 w-80 ${
        expanded ? `py-5 px-6` : `h-16 pl-8`
      } self-stretch bg-black bg-opacity-0 hover:bg-opacity-10 cursor-pointer transition duration-100 hidden lg:flex`}
      onClick={() => setExpanded(!expanded)}
    >
      <i
        className={`fas fa-chevron-${
          expanded ? `left mr-3` : `right`
        } text-2xl text-white text-opacity-60`}
      />
    </div>
  </nav>
);

export default SidebarNav;
